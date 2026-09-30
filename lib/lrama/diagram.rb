# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Diagram
    class << self
      # @rbs (IO out, Grammar grammar, String template_name) -> void
      def render(out:, grammar:, template_name: 'diagram/diagram.html')
        return unless require_railroad_diagrams
        new(out: out, grammar: grammar, template_name: template_name).render
      end

      # @rbs () -> bool
      def require_railroad_diagrams
        require "railroad_diagrams"
        true
      rescue LoadError
        warn "railroad_diagrams is not installed. Please run `bundle install`."
        false
      end
    end

    # @rbs (IO out, Grammar grammar, String template_name) -> void
    def initialize(out:, grammar:, template_name: 'diagram/diagram.html')
      @grammar = grammar
      @out = out
      @template_name = template_name
    end

    # @rbs () -> void
    def render
      @out << ERB.render(template_file, output: self)
    end

    # @rbs () -> string
    def default_style
      RailroadDiagrams::Style::default_style
    end

    # @rbs () -> Array[Hash[Symbol, (String | Array[String])]]
    def linked_sections
      document = RailroadDiagrams::Document.new(title: "Lrama syntax diagrams", theme: :default)
      action_symbols = @grammar.rules.select(&:original_rule).map(&:lhs)
      @grammar.rules.reject(&:original_rule).group_by { |rule| rule.lhs.id.s_value }.each do |name, rules|
        alternatives = rules.map do |rule|
          diagram_rule = rule.dup
          diagram_rule.rhs = rule.rhs - action_symbols
          diagram_rule.to_diagrams
        end
        document.add_rule(name, RailroadDiagrams::Choice.new(0, *alternatives))
      end
      document.rule_sections
    end

    private

    # @rbs () -> string
    def template_dir
      File.expand_path('../../template', __dir__)
    end

    # @rbs () -> string
    def template_file
      File.join(template_dir, @template_name)
    end

  end
end
