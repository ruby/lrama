# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    # Warning rationale: Parameterized rule names conflicting with symbol names
    # - When a %rule name is identical to a terminal or non-terminal symbol name,
    #   it reduces grammar readability and may cause unintended behavior
    # - Detecting these conflicts helps improve grammar definition quality
    class NameConflicts
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        diagnostics(grammar).each do |diagnostic|
          @emitter.warn(diagnostic, message: "warning: #{diagnostic.message}")
        end
      end

      # @rbs (Lrama::Grammar grammar) -> Array[Lrama::Diagnostic]
      def diagnostics(grammar)
        return [] unless @warnings
        return [] if grammar.parameterized_rules.empty?

        symbol_names = collect_symbol_names(grammar)
        conflict_diagnostics(grammar.parameterized_rules, symbol_names)
      end

      private

      # @rbs (Lrama::Grammar grammar) -> Set[String]
      def collect_symbol_names(grammar)
        symbol_names = Set.new

        collect_term_names(grammar.terms, symbol_names)
        collect_nterm_names(grammar.nterms, symbol_names)

        symbol_names
      end

      # @rbs (Array[untyped] terms, Set[String] symbol_names) -> void
      def collect_term_names(terms, symbol_names)
        terms.each do |term|
          symbol_names.add(term.id.s_value)
          symbol_names.add(term.alias_name) if term.alias_name
        end
      end

      # @rbs (Array[untyped] nterms, Set[String] symbol_names) -> void
      def collect_nterm_names(nterms, symbol_names)
        nterms.each do |nterm|
          symbol_names.add(nterm.id.s_value)
        end
      end

      # @rbs (Array[untyped] parameterized_rules, Set[String] symbol_names) -> Array[Lrama::Diagnostic]
      def conflict_diagnostics(parameterized_rules, symbol_names)
        parameterized_rules.each_with_object([]) do |param_rule, diagnostics|
          next unless symbol_names.include?(param_rule.name)

          diagnostics << Lrama::Diagnostic.new(
            id: "parameterized_rule.name_conflict",
            severity: :warning,
            message: "parameterized rule name \"#{param_rule.name}\" conflicts with symbol name",
            details: { "name" => param_rule.name },
            suggestion: "Rename the parameterized rule or the conflicting grammar symbol."
          )
        end
      end
    end
  end
end
