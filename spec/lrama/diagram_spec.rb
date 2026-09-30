# frozen_string_literal: true

require "rexml/document"
require "railroad_diagrams"

RSpec.describe Lrama::Diagram do
  let(:diagram) {
    Lrama::Diagram.new(
      out: out,
      grammar: grammar,
    )
  }
  let(:out) { StringIO.new }
  let(:grammar_file_path) { fixture_path("common/basic.y") }
  let(:text) { File.read(grammar_file_path) }
  let(:grammar) do
    grammar = Lrama::Parser.new(text, grammar_file_path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end

  describe ".render" do
    it "renders a diagram" do
      expect { Lrama::Diagram.render(out: out, grammar: grammar) }.not_to raise_error
      expect(out.string).to include('<h2 class="diagram-header">$accept</h2>')
      expect(out.string).to include('<h2 class="diagram-header">unused</h2>')
      expect(out.string).to include("<svg")
      expect(out.string).to include('<section id="rule-program">')
      expect(out.string).to include('href="#rule-program"')
      expect(out.string).to include("Referenced by:")
    end
  end

  describe ".require_railroad_diagrams" do
    context "when railroad_diagrams is installed" do
      it "requires railroad_diagrams" do
        expect { Lrama::Diagram.require_railroad_diagrams }.not_to raise_error
      end
    end

    context "when railroad_diagrams is not installed" do
      before do
        allow(Lrama::Diagram).to receive(:require).with("railroad_diagrams").and_raise(LoadError)
      end

      it "warns" do
        expect { Lrama::Diagram.require_railroad_diagrams }.to output(/railroad_diagrams is not installed/).to_stderr
      end
    end
  end

  describe "#render" do
    before do
      Lrama::Diagram.require_railroad_diagrams
    end

    it "renders a diagram" do
      expect { diagram.render }.not_to raise_error
      expect(out.string).to include('<h2 class="diagram-header">$accept</h2>')
      expect(out.string).to include('<h2 class="diagram-header">unused</h2>')
      expect(out.string).to include("<svg")
    end
  end

  describe "#default_style" do
    before do
      Lrama::Diagram.require_railroad_diagrams
    end

    it "returns the default style" do
      expect(diagram.default_style).to eq RailroadDiagrams::Style::default_style
    end
  end

  describe "linked diagrams" do
    it "preserves rule order and includes references" do
      sections = diagram.linked_sections

      expect(sections.map { |section| section[:name] }).to eq(%w[$accept program class strings_1 strings_2 string_1 string_2 string unused])
      expect(sections.map { |section| section[:id] }.uniq.size).to eq(sections.size)
      expect(sections.find { |section| section[:name] == "program" }[:referenced_by]).to eq(["$accept"])
      expect(sections.find { |section| section[:name] == "string_1" }[:referenced_by]).to eq(["strings_1", "strings_2"])
      expect(sections.find { |section| section[:name] == "unused" }[:referenced_by]).to eq([])
      sections.each do |section|
        expect(REXML::Document.new(section[:svg]).root.name).to eq("svg")
      end
    end

    context "with midrule actions" do
      let(:grammar_file_path) { "midrule-actions.y" }
      let(:text) do
        <<~GRAMMAR
          %union { int i; }
          %token <i> NUMBER
          %type <i> start value
          %%
          start: { setup(); } value { checkpoint(); } empty
               | value { $<i>$ = $1; } empty { $$ = $<i>2; }
               | actions;
          value: NUMBER;
          empty: %empty;
          actions: { setup(); } { finish(); };
        GRAMMAR
      end

      it "omits action rules and references while preserving empty grammar rules" do
        original_rules = grammar.rules.map(&:display_name)
        action_names = grammar.rules.select(&:original_rule).map { |rule| rule.lhs.id.s_value }
        expect(action_names).to include("$@1", "@3")

        sections = diagram.linked_sections
        expect(sections.map { |section| section[:name] }).to eq(%w[$accept start value empty actions])
        start = sections.find { |section| section[:name] == "start" }
        svg = REXML::Document.new(start[:svg])
        expect(REXML::XPath.match(svg, "//text").map(&:text)).to eq(%w[value empty value empty actions])
        expect(sections.find { |section| section[:name] == "empty" }[:referenced_by]).to eq(["start"])
        actions = sections.find { |section| section[:name] == "actions" }
        expect(REXML::XPath.match(REXML::Document.new(actions[:svg]), "//text")).to eq([])

        diagram.render
        action_names.each { |name| expect(out.string).not_to include(name) }
        ids = out.string.scan(/\bid="([^"]+)"/).flatten
        targets = out.string.scan(/\bhref="#([^"]+)"/).flatten
        expect(targets - ids).to eq([])
        expect(out.string).to include('href="#rule-empty"')
        expect(grammar.rules.map(&:display_name)).to eq(original_rules)
      end
    end

    it "renders native links and reverse references without text diagrams" do
      sections = diagram.linked_sections
      expect(diagram).to receive(:linked_sections).once.and_return(sections)
      diagram.render

      ids = out.string.scan(/\bid="([^"]+)"/).flatten
      targets = out.string.scan(/\bhref="#([^"]+)"/).flatten
      expect(ids.uniq).to eq(ids)
      expect(targets).to include("rule-program", "rule-accept")
      expect(targets - ids).to eq([])
      expect(out.string).to include('<section id="rule-unused">')
      expect(out.string).to include("Referenced by:")
      expect(out.string).not_to include("<details", "<pre", "Text diagram")
      expect(out.string).not_to include("<script")
    end

    it "escapes rule names and leaves undefined references unlinked" do
      name = '<rule & "name">'
      symbols = [name, "missing", "rule name"].map do |label|
        Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: label), term: false)
      end
      rules = [
        Lrama::Grammar::Rule.new(lhs: symbols[0], rhs: symbols[0..1]),
        Lrama::Grammar::Rule.new(lhs: symbols[2], rhs: []),
      ]
      custom_grammar = double(:grammar, rules: rules)
      linked = Lrama::Diagram.new(out: out, grammar: custom_grammar)
      sections = linked.linked_sections
      expect(sections.map { |section| section[:id] }).to eq(["rule-rule-name", "rule-rule-name-2"])
      svg = REXML::Document.new(sections.first[:svg])
      hrefs = REXML::XPath.match(svg, "//*[@href]").map { |element| element.attributes["href"] }
      expect(hrefs).to eq(["#rule-rule-name"])
      linked.render
      expect(out.string).to include("<h2 class=\"diagram-header\">#{RailroadDiagrams.escape_html(name)}</h2>")
      expect(out.string).not_to include(name)
    end
  end
end
