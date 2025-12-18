# frozen_string_literal: true

RSpec.describe "Semantic Predicates" do
  let(:grammar_file_path) { fixture_path("semantic_predicate/basic.y") }

  describe "basic semantic predicate" do
    it "generates parser with predicate functions" do
      path = grammar_file_path
      text = File.read(path)

      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      widget_rules = grammar.rules.select { |r| r.lhs&.id&.s_value == "widget" }
      expect(widget_rules).not_to be_empty
      rules_with_predicates = widget_rules.select { |r| r.predicates.any? }
      expect(rules_with_predicates).not_to be_empty
      rules_with_predicates.each do |rule|
        rule.predicates.each do |predicate|
          expect(predicate).to be_a(Lrama::Grammar::SemanticPredicate)
          expect(predicate.code).to match(/new_syntax/)
          expect(predicate.index).not_to be_nil
        end
      end
    end

    it "assigns globally unique indexes to predicates across different rules" do
      path = grammar_file_path
      text = File.read(path)
      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      all_predicates = grammar.rules.flat_map(&:predicates)
      expect(all_predicates.count).to eq(2)
      indexes = all_predicates.map(&:index)
      expect(indexes).to eq(indexes.uniq), "Predicate indexes should be globally unique"
      expect(indexes.sort).to eq([0, 1])
      predicate_0 = all_predicates.find { |p| p.index == 0 }
      predicate_1 = all_predicates.find { |p| p.index == 1 }
      expect(predicate_0).not_to be_nil
      expect(predicate_1).not_to be_nil
      expect(predicate_0.code).to eq("new_syntax")
      expect(predicate_1.code).to eq("!new_syntax")
    end

    it "generates correct C code with predicate functions" do
      path = grammar_file_path
      text = File.read(path)

      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      tracer = Lrama::Tracer.new(Lrama::Logger.new)
      states = Lrama::States.new(grammar, tracer)
      states.compute
      context = Lrama::Context.new(states)
      output_string = StringIO.new
      output = Lrama::Output.new(
        out: output_string,
        output_file_path: "test.c",
        template_name: "bison/yacc.c",
        grammar_file_path: path,
        context: context,
        grammar: grammar
      )
      output.render
      generated_code = output_string.string
      expect(generated_code).to include("yypredicate_")
      expect(generated_code).to match(/static int\s+yypredicate_\d+\s*\(void\)/)
      expect(generated_code).to include("new_syntax")
    end

    it "generates unique predicate functions in C code for each predicate" do
      path = grammar_file_path
      text = File.read(path)
      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      tracer = Lrama::Tracer.new(Lrama::Logger.new)
      states = Lrama::States.new(grammar, tracer)
      states.compute
      context = Lrama::Context.new(states)
      output_string = StringIO.new
      output = Lrama::Output.new(
        out: output_string,
        output_file_path: "test.c",
        template_name: "bison/yacc.c",
        grammar_file_path: path,
        context: context,
        grammar: grammar
      )

      output.render
      generated_code = output_string.string
      predicate_functions = generated_code.scan(/yypredicate_(\d+)\s*\(void\)/)
      function_indexes = predicate_functions.flatten.map(&:to_i)
      expect(function_indexes.count).to eq(2)
      expect(function_indexes).to eq(function_indexes.uniq), "Generated predicate function names should be unique"
      all_predicates = grammar.rules.flat_map(&:predicates)
      grammar_indexes = all_predicates.map(&:index).sort
      expect(function_indexes.sort).to eq(grammar_indexes), "Generated function indexes should match grammar predicate indexes"
      expect(generated_code).to include("yypredicate_0")
      expect(generated_code).to include("yypredicate_1")
      expect(generated_code).to match(/yypredicate_0.*new_syntax/m)
      expect(generated_code).to match(/yypredicate_1.*!new_syntax/m)
    end
  end

  describe "predicate with complex expression" do
    let(:complex_grammar) do
      <<~GRAMMAR
        %{
        #include <stdio.h>
        static int version = 2;
        int yylex(void);
        void yyerror(const char *s);
        %}

        %token FEATURE

        %%

        program
            : {version >= 2}? FEATURE { printf("v2+\\n"); }
            | FEATURE { printf("v1\\n"); }
            ;

        %%

        int yylex(void) { return 0; }
        void yyerror(const char *s) { fprintf(stderr, "%s\\n", s); }
      GRAMMAR
    end

    it "parses complex predicate expressions" do
      grammar = Lrama::Parser.new(complex_grammar, "complex.y").parse
      grammar.prepare
      rules_with_predicates = grammar.rules.select { |r| r.predicates.any? }
      expect(rules_with_predicates).not_to be_empty
      predicate = rules_with_predicates.first.predicates.first
      expect(predicate.code).to eq("version >= 2")
    end
  end

  describe "context-sensitive keywords" do
    let(:context_sensitive_grammar_path) { fixture_path("semantic_predicate/context_sensitive_keyword.y") }

    it "handles context-sensitive 'async' keyword using predicates" do
      path = context_sensitive_grammar_path
      text = File.read(path)
      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      declaration_rules = grammar.rules.select { |r| r.lhs&.id&.s_value == "declaration" }
      expect(declaration_rules).not_to be_empty
      rules_with_predicates = declaration_rules.select { |r| r.predicates.any? }
      expect(rules_with_predicates).not_to be_empty
      predicate = rules_with_predicates.first.predicates.first
      expect(predicate.code).to eq("is_at_function_start()")
      expect(predicate.position).to eq(:leading)  # Predicate at the start affects prediction
    end

    it "generates C code with context-sensitive predicate functions" do
      path = context_sensitive_grammar_path
      text = File.read(path)
      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      grammar.validate!
      tracer = Lrama::Tracer.new(Lrama::Logger.new)
      states = Lrama::States.new(grammar, tracer)
      states.compute
      context = Lrama::Context.new(states)
      output_string = StringIO.new
      output = Lrama::Output.new(
        out: output_string,
        output_file_path: "context_sensitive.c",
        template_name: "bison/yacc.c",
        grammar_file_path: path,
        context: context,
        grammar: grammar
      )

      output.render
      generated_code = output_string.string
      expect(generated_code).to include("yypredicate_")
      expect(generated_code).to match(/static int\s+yypredicate_\d+\s*\(void\)/)
      expect(generated_code).to include("is_at_function_start()")
      expect(generated_code).to match(/\/\* Semantic predicate: \{is_at_function_start\(\)\}\? \*\//)
    end

    it "demonstrates practical use case: distinguishing async keyword from identifier" do
      path = context_sensitive_grammar_path
      text = File.read(path)

      grammar = Lrama::Parser.new(text, path).parse
      grammar.prepare
      declaration_rules = grammar.rules.select { |r| r.lhs&.id&.s_value == "declaration" }
      expect(declaration_rules.count).to be >= 2
      with_predicate = declaration_rules.count { |r| r.predicates.any? }
      expect(with_predicate).to be >= 1
      without_predicate = declaration_rules.count { |r| r.predicates.empty? }
      expect(without_predicate).to be >= 1
    end
  end

  describe "multiple predicates in sequence" do
    let(:multiple_predicates_grammar) do
      <<~GRAMMAR
        %{
        #include <stdio.h>
        static int is_modern_mode(void) { return 1; }
        static int supports_feature_x(void) { return 1; }
        int yylex(void);
        void yyerror(const char *s);
        %}

        %token FEATURE_X FEATURE_Y

        %%

        program
            : {is_modern_mode()}? {supports_feature_x()}? FEATURE_X
              { printf("Modern mode with feature X\\n"); }
            | FEATURE_Y
              { printf("Fallback\\n"); }
            ;

        %%

        int yylex(void) { return 0; }
        void yyerror(const char *s) { fprintf(stderr, "%s\\n", s); }
      GRAMMAR
    end

    it "handles multiple predicates in the same rule" do
      grammar = Lrama::Parser.new(multiple_predicates_grammar, "multi_pred.y").parse
      grammar.prepare
      rules_with_multiple_predicates = grammar.rules.select { |r| r.predicates.count > 1 }
      expect(rules_with_multiple_predicates).not_to be_empty
      rule = rules_with_multiple_predicates.first
      expect(rule.predicates.count).to eq(2)
      expect(rule.predicates[0].code).to eq("is_modern_mode()")
      expect(rule.predicates[1].code).to eq("supports_feature_x()")
      expect(rule.predicates[0].position).to eq(:leading)
      expect(rule.predicates[1].position).to eq(:leading)
    end

    it "assigns sequential unique indexes to multiple predicates in the same rule" do
      grammar = Lrama::Parser.new(multiple_predicates_grammar, "multi_pred.y").parse
      grammar.prepare
      rules_with_multiple_predicates = grammar.rules.select { |r| r.predicates.count > 1 }
      expect(rules_with_multiple_predicates).not_to be_empty
      rule = rules_with_multiple_predicates.first
      expect(rule.predicates.count).to eq(2)
      indexes = rule.predicates.map(&:index)
      expect(indexes).to eq(indexes.uniq), "Predicate indexes within the same rule should be unique"
      expect(indexes[1] - indexes[0]).to eq(1), "Predicate indexes should be sequential"
      all_predicates = grammar.rules.flat_map(&:predicates)
      all_indexes = all_predicates.map(&:index)
      expect(all_indexes).to eq(all_indexes.uniq), "All predicate indexes across the entire grammar should be globally unique"
    end
  end
end
