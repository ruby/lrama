# frozen_string_literal: true

require "stringio"

RSpec.describe "table backends" do
  let(:text) { File.read(grammar_file_path) }
  let(:grammar) do
    grammar = Lrama::Parser.new(text, grammar_file_path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end
  let(:states) { s = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new)); s.compute; s }
  let(:context) { Lrama::Context.new(states) }
  let(:grammar_file_path) { fixture_path("common/no_union.y") }

  [
    [:rust, Lrama::Backend::Rust, "rs", "pub trait Lexer"],
    [:ruby, Lrama::Backend::Ruby, "rb", "class Parser"],
    [:javascript, Lrama::Backend::JavaScript, "mjs", "export default class Parser"],
    [:cpp, Lrama::Backend::Cpp, "cpp", "class Parser"],
    [:python, Lrama::Backend::Python, "py", "class Parser:"],
  ].each do |name, klass, extension, marker|
    context name do
      let(:backend) { klass.new(context: context, grammar: grammar, options: nil) }

      it "is registered" do
        expect(Lrama::Backend.for(name)).to eq(klass)
        expect(backend.file_extension).to eq(extension)
      end

      it "renders a parser skeleton" do
        out = StringIO.new
        Lrama::Output.new(
          out: out,
          output_file_path: "parser.#{extension}",
          backend: backend,
          grammar_file_path: grammar_file_path,
          context: context,
          grammar: grammar,
        ).render

        expect(out.string).to include(marker)
        expect(out.string).to include("YYTRANSLATE")
        expect(out.string).not_to match(/\[@oline@\]/)
        expect(out.string).not_to match(/\[@ofile@\]/)
      end
    end
  end

  describe Lrama::Backend::Ruby do
    it "translates rule references to Ruby stack values" do
      y = <<~GRAMMAR
        %token NUMBER
        %%
        program: NUMBER { $$ = $1; };
        %%
      GRAMMAR
      grammar = Lrama::Parser.new(y, "parse.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      backend = described_class.new(context: Lrama::Context.new(states), grammar: grammar, options: nil)
      rule = grammar.rules.find { |r| r.lhs.id.s_value == "program" }

      expect(rule.translated_code(grammar, backend.translator)).to eq(" yyval = val[1]; ")
    end
  end

  describe "calc grammar" do
    let(:calc_text) do
      <<~GRAMMAR
        %token NUM PLUS
        %%
        program: expr { $$ = $1; };
        expr: NUM
            | expr PLUS NUM { $$ = $1 + $3; };
        %%
      GRAMMAR
    end

    [
      [:rust, "rs"],
      [:ruby, "rb"],
      [:javascript, "mjs"],
      [:cpp, "cpp"],
      [:python, "py"],
    ].each do |language, extension|
      it "renders a calc parser for #{language}" do
        grammar_file_path = "calc.#{extension}.y"
        grammar = Lrama::Parser.new(calc_text, grammar_file_path).parse
        grammar.prepare
        grammar.validate!

        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        context = Lrama::Context.new(states)
        backend = Lrama::Backend.for(language).new(context: context, grammar: grammar, options: nil)
        out = StringIO.new

        Lrama::Output.new(
          out: out,
          output_file_path: "parser.#{extension}",
          backend: backend,
          grammar_file_path: grammar_file_path,
          context: context,
          grammar: grammar,
        ).render

        expect(out.string).to include("YYTRANSLATE")
      end
    end
  end
end
