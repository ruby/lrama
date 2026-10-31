# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # _rhs holds original RHS element. Use rhs to refer to Symbol.
    # _rhs_locations holds the source location of each corresponding _rhs ID.
    class Rule
      # @rbs!
      #
      #   interface _DelegatedMethods
      #     def lhs: -> Grammar::Symbol
      #     def rhs: -> Array[Grammar::Symbol]
      #   end

      attr_accessor :id #: Integer
      attr_accessor :_lhs #: Grammar::Symbol::Id
      attr_accessor :lhs #: Grammar::Symbol
      attr_accessor :lhs_tag #: Lexer::Token::Tag?
      attr_accessor :_rhs #: Array[Grammar::Symbol::Id]
      attr_accessor :rhs #: Array[Grammar::Symbol]
      attr_accessor :token_code #: Lexer::Token::UserCode?
      attr_accessor :position_in_original_rule_rhs #: Integer
      attr_accessor :nullable #: bool
      attr_accessor :precedence_sym #: Grammar::Symbol?
      attr_accessor :lineno #: Integer?
      attr_accessor :_lhs_location #: Lexer::Location?
      attr_accessor :_rhs_locations #: Array[Lexer::Location?]?
      attr_accessor :original_rule #: Rule

      # @rbs (?id: Integer?, ?_lhs: Grammar::Symbol::Id?, ?lhs: Grammar::Symbol?, ?lhs_tag: Lexer::Token::Tag?,
      #      ?_rhs: Array[Grammar::Symbol::Id]?, ?rhs: Array[Grammar::Symbol]?, ?token_code: Lexer::Token::UserCode?,
      #      ?position_in_original_rule_rhs: Integer?, ?nullable: bool?, ?precedence_sym: Grammar::Symbol?,
      #      ?lineno: Integer?, ?_lhs_location: Lexer::Location?, ?_rhs_locations: Array[Lexer::Location?]?) -> void
      def initialize(id: nil, _lhs: nil, lhs: nil, lhs_tag: nil, _rhs: nil, rhs: nil, token_code: nil,
                     position_in_original_rule_rhs: nil, nullable: nil, precedence_sym: nil, lineno: nil,
                     _lhs_location: nil, _rhs_locations: nil)
        @id = id
        @_lhs = _lhs
        @lhs = lhs
        @lhs_tag = lhs_tag
        @_rhs = _rhs
        @rhs = rhs
        @token_code = token_code
        @position_in_original_rule_rhs = position_in_original_rule_rhs
        @nullable = nullable
        @precedence_sym = precedence_sym
        @lineno = lineno
        @_lhs_location = _lhs_location
        @_rhs_locations = _rhs_locations
      end

      # @rbs (Rule other) -> bool
      def ==(other)
        self.class == other.class &&
        self.lhs == other.lhs &&
        self.lhs_tag == other.lhs_tag &&
        self.rhs == other.rhs &&
        self.token_code == other.token_code &&
        self.position_in_original_rule_rhs == other.position_in_original_rule_rhs &&
        self.nullable == other.nullable &&
        self.precedence_sym == other.precedence_sym &&
        self.lineno == other.lineno
      end

      # @rbs () -> String
      def display_name
        l = lhs.name
        r = empty_rule? ? "ε" : rhs.map(&:name).join(" ")
        "#{l} -> #{r}"
      end

      # @rbs () -> String
      def display_name_without_action
        l = lhs.name
        r = empty_rule? ? "ε" : rhs.map do |r|
          r.name if r.first_set.any?
        end.compact.join(" ")

        "#{l} -> #{r}"
      end

      # @rbs () -> (RailroadDiagrams::Skip | RailroadDiagrams::Sequence)
      def to_diagrams
        if rhs.empty?
          RailroadDiagrams::Skip.new
        else
          RailroadDiagrams::Sequence.new(*rhs_to_diagram)
        end
      end

      # Used by #user_actions
      #
      # @rbs () -> String
      def as_comment
        l = lhs.name
        r = empty_rule? ? "%empty" : rhs.map(&:display_name).join(" ")

        "#{l}: #{r}"
      end

      # @rbs () -> String
      def with_actions
        "#{display_name} {#{token_code&.s_value}}"
      end

      # opt_nl: ε     <-- empty_rule
      #       | '\n'  <-- not empty_rule
      #
      # @rbs () -> bool
      def empty_rule?
        rhs.empty?
      end

      # @rbs () -> Precedence?
      def precedence
        precedence_sym&.precedence
      end

      # @rbs () -> bool
      def initial_rule?
        id == 0
      end

      # @rbs (Grammar grammar) -> String?
      def translated_code(grammar)
        return nil unless token_code

        Code::RuleAction.new(type: :rule_action, token_code: token_code, rule: self, grammar: grammar).translated_code
      end

      # @rbs () -> bool
      def contains_at_reference?
        return false unless token_code

        token_code.references.any? {|r| r.type == :at }
      end

      private

      # @rbs () -> Array[(RailroadDiagrams::Terminal | RailroadDiagrams::NonTerminal)]
      def rhs_to_diagram
        rhs.map do |r|
          if r.term
            RailroadDiagrams::Terminal.new(r.name)
          else
            RailroadDiagrams::NonTerminal.new(r.name)
          end
        end
      end
    end
  end
end
