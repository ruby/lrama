# rbs_inline: enabled
# frozen_string_literal: true

require "erb"

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

    if ERB.instance_method(:initialize).parameters.last.first == :key
      # @rbs (String input) -> ERB
      def self.erb(input)
        ERB.new(input, trim_mode: nil)
      end
    else
      # @rbs override
      def self.erb(input)
        ERB.new(input, nil, nil)
      end
    end

    # @rbs () -> void
    def render
      RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
      @out << render_template(template_file)
    end

    # @rbs () -> string
    def default_style
      RailroadDiagrams::Style::default_style
    end

    # @rbs () -> string
    def diagrams
      result = +''
      @grammar.unique_rule_s_values.each do |s_value|
        diagrams =
          @grammar.select_rules_by_s_value(s_value).map { |r| r.to_diagrams }
        add_diagram(
          s_value,
          RailroadDiagrams::Diagram.new(
            RailroadDiagrams::Choice.new(0, *diagrams),
          ),
          result
        )
      end
      result
    end

    private

    # @rbs (String file) -> string
    def render_template(file)
      erb = self.class.erb(File.read(file))
      erb.filename = file
      erb.result_with_hash(output: self)
    end

    # @rbs () -> string
    def template_dir
      File.expand_path('../../template', __dir__)
    end

    # @rbs () -> string
    def template_file
      File.join(template_dir, @template_name)
    end

    # @rbs (String name, RailroadDiagrams::Diagram diagram, String result) -> void
    def add_diagram(name, diagram, result)
      result << "\n<h2 class=\"diagram-header\">#{RailroadDiagrams.escape_html(name)}</h2>"
      diagram.write_svg(result.method(:<<))
      result << "\n"
    end
  end
end
