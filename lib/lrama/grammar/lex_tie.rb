# rbs_inline: enabled
# frozen_string_literal: true

require "set"

module Lrama
  class Grammar
    # Stores PSLR lexical ties and explicit no-tie declarations.
    #
    # Lexical ties expand acc(sp); they never resolve a scanner conflict by
    # themselves. Conflict selection is still handled by %lex-prec.
    class LexTie
      class OperandGroup
        attr_reader :names #: Array[String]
        attr_reader :kind #: ::Symbol

        # @rbs (names: Array[String], kind: ::Symbol) -> void
        def initialize(names:, kind:)
          @names = names
          @kind = kind
        end
      end

      class Declaration
        attr_reader :kind #: ::Symbol
        attr_reader :groups #: Array[OperandGroup]
        attr_reader :lineno #: Integer

        # @rbs (kind: ::Symbol, groups: Array[OperandGroup], lineno: Integer) -> void
        def initialize(kind:, groups:, lineno:)
          @kind = kind
          @groups = groups
          @lineno = lineno
        end
      end

      class Decision
        attr_reader :kind #: ::Symbol
        attr_reader :specificity #: Integer
        attr_reader :lineno #: Integer

        # @rbs (kind: ::Symbol, specificity: Integer, lineno: Integer) -> void
        def initialize(kind:, specificity:, lineno:)
          @kind = kind
          @specificity = specificity
          @lineno = lineno
        end
      end

      attr_reader :ties #: Hash[String, Set[String]]
      attr_reader :no_ties #: Set[[String, String]]
      attr_reader :declarations #: Array[Declaration]

      # @rbs () -> void
      def initialize
        @ties = Hash.new { |h, k| h[k] = Set.new([k]) }
        @no_ties = Set.new
        @declarations = []
      end

      # @rbs (String left, String right) -> void
      def add_tie(left, right)
        left_set = tied_names(left)
        right_set = tied_names(right)
        merged = left_set | right_set

        merged.each do |name|
          @ties[name] = merged.dup
        end
      end

      # @rbs (String left, String right) -> void
      def add_no_tie(left, right)
        @no_ties << pair_key(left, right)
      end

      # @rbs (groups: Array[OperandGroup], ?lineno: Integer) -> void
      def add_tie_declaration(groups:, lineno: 0)
        @declarations << Declaration.new(kind: :tie, groups: groups, lineno: lineno)
      end

      # @rbs (groups: Array[OperandGroup], ?lineno: Integer) -> void
      def add_no_tie_declaration(groups:, lineno: 0)
        @declarations << Declaration.new(kind: :no_tie, groups: groups, lineno: lineno)
      end

      # @rbs (Array[String] token_names, Set[[String, String]] conflict_pairs) -> void
      def finalize!(token_names, conflict_pairs)
        decisions = {} #: Hash[[String, String], Decision]

        @declarations.each do |declaration|
          declaration_pairs(declaration, token_names, conflict_pairs).each do |pair, specificity|
            apply_decision(decisions, pair, Decision.new(kind: declaration.kind, specificity: specificity, lineno: declaration.lineno))
          end
        end

        rebuild_relations(token_names, decisions)
      end

      # @rbs (String name) -> Set[String]
      def tied_names(name)
        @ties[name].dup
      end

      # @rbs (String left, String right) -> bool
      def tied?(left, right)
        tied_names(left).include?(right)
      end

      # @rbs (String left, String right) -> bool
      def no_tie?(left, right)
        @no_ties.include?(pair_key(left, right))
      end

      # @rbs () -> Array[[String, String]]
      def no_ties_conflicting_with_ties
        @no_ties.select do |left, right|
          tied?(left, right)
        end
      end

      private

      # @rbs (Hash[[String, String], Decision] decisions, [String, String] pair, Decision decision) -> void
      def apply_decision(decisions, pair, decision)
        current = decisions[pair]
        if current.nil? || current.specificity < decision.specificity
          decisions[pair] = decision
          return
        end

        if current.specificity == decision.specificity && current.kind != decision.kind
          raise "%lex-tie and %lex-no-tie conflict for #{pair.join(' ')}."
        end
      end

      # @rbs (Declaration declaration, Array[String] token_names, Set[[String, String]] conflict_pairs) -> Array[[[String, String], Integer]]
      def declaration_pairs(declaration, token_names, conflict_pairs)
        pairs = [] #: Array[[[String, String], Integer]]

        declaration.groups.combination(2) do |left_group, right_group|
          next unless left_group && right_group

          specificity = group_specificity(left_group, right_group)
          left_names = names_for_group(left_group, token_names)
          right_names = names_for_group(right_group, token_names)

          left_names.product(right_names).each do |left, right|
            next if left == right

            pair = pair_key(left, right)
            if declaration.kind == :tie && specificity < 3
              next unless conflict_pairs.include?(pair)
            end

            if declaration.kind == :no_tie && specificity < 3
              next unless conflict_pairs.include?(pair)
            end

            pairs << [pair, specificity]
          end
        end

        pairs
      end

      # @rbs (OperandGroup group, Array[String] token_names) -> Array[String]
      def names_for_group(group, token_names)
        return token_names if group.kind == :all

        group.names
      end

      # @rbs (OperandGroup left, OperandGroup right) -> Integer
      def group_specificity(left, right)
        return 3 if left.kind == :token && right.kind == :token
        return 0 if left.kind == :all && right.kind == :all
        return 2 if left.kind == :token || right.kind == :token

        1
      end

      # @rbs (Array[String] token_names, Hash[[String, String], Decision] decisions) -> void
      def rebuild_relations(token_names, decisions)
        parents = {} #: Hash[String, String]
        tie_specificities = {} #: Hash[[String, String], Integer]
        token_names.each {|name| parents[name] = name }

        decisions.each do |pair, decision|
          next unless decision.kind == :tie

          union(parents, pair[0], pair[1])
          tie_specificities[pair] = decision.specificity
        end

        @ties = Hash.new { |h, k| h[k] = Set.new([k]) }
        groups = token_names.group_by {|name| root(parents, name) }
        groups.each_value do |names|
          tied = names.to_set
          names.each {|name| @ties[name] = tied.dup }
        end

        closure_specificities = {} #: Hash[[String, String], Integer]
        groups.each_value do |names|
          names.combination(2) do |left, right|
            next unless left && right

            pair = pair_key(left, right)
            closure_specificities[pair] = tie_specificity_between(left, right, tie_specificities)
          end
        end

        @no_ties = Set.new
        decisions.each do |pair, decision|
          next unless decision.kind == :no_tie

          tie_specificity = closure_specificities[pair]
          if tie_specificity && decision.specificity >= tie_specificity
            raise "%lex-no-tie #{pair[0]} #{pair[1]} conflicts with an existing %lex-tie closure."
          end

          @no_ties << pair unless tie_specificity
        end
      end

      # @rbs (Hash[String, String] parents, String name) -> String
      def root(parents, name)
        parents[name] ||= name
        while parents[name] != name
          parents[name] = parents[parents[name]]
          name = parents[name]
        end
        name
      end

      # @rbs (Hash[String, String] parents, String left, String right) -> void
      def union(parents, left, right)
        left_root = root(parents, left)
        right_root = root(parents, right)
        return if left_root == right_root

        parents[right_root] = left_root
      end

      # Compute closure specificity between two tokens via tie graph BFS.
      # Path specificity = min(edge specificities on the path).
      # Result = max over all paths connecting left and right.
      # @rbs (String left, String right, Hash[[String, String], Integer] tie_specificities) -> Integer
      def tie_specificity_between(left, right, tie_specificities)
        direct = tie_specificities[pair_key(left, right)]
        return direct if direct

        # Build adjacency list from tie edges
        graph = Hash.new { |h, k| h[k] = [] } #: Hash[String, Array[[String, Integer]]]
        tie_specificities.each do |(a, b), specificity|
          graph[a] << [b, specificity]
          graph[b] << [a, specificity]
        end

        return 0 unless graph.key?(left)

        # BFS/Dijkstra-like: find path from left to right maximizing min-edge specificity
        # best[node] = best (max) path-min-specificity to reach node from left
        best = { left => Float::INFINITY } #: Hash[String, Integer | Float]
        queue = [[left, Float::INFINITY]] #: Array[[String, Integer | Float]]

        until queue.empty?
          node, path_min = queue.shift
          next unless node && path_min

          graph[node].each do |neighbor, edge_spec|
            new_min = [path_min, edge_spec].min
            if !best.key?(neighbor) || new_min > best[neighbor]
              best[neighbor] = new_min
              queue << [neighbor, new_min]
            end
          end
        end

        result = best[right]
        result && result != Float::INFINITY ? result.to_i : 0
      end

      # @rbs (String left, String right) -> [String, String]
      def pair_key(left, right)
        left <= right ? [left, right] : [right, left]
      end
    end
  end
end
