# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "external lexer contexts" do
  [false, true].product([:identifier, :alias_before, :alias_after]).each do |patterns, operand|
    it "exports #{operand} context declarations to a separate lexer #{patterns ? 'with' : 'without'} scanner patterns" do
      Dir.mktmpdir("lrama-lexer-context") do |dir|
        compiler = ENV.fetch("COMPILER", "cc")
        cpp = compiler.include?("++")
        grammar = File.join(dir, "parser.y")
        output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
        lexer = File.join(dir, cpp ? "lexer.cpp" : "lexer.c")
        executable = File.join(dir, "parser")
        File.write(grammar, <<~GRAMMAR)
          %define lr.type pslr
          %define api.pslr.state-member current_state
          %parse-param {struct parse_params *p}
          %lex-param {struct parse_params *p}
          %code requires {
            struct parse_params { int current_state; int reads; };
          }
          %code provides {
            int yylex(YYSTYPE *value, struct parse_params *p);
            int yyerror(YYLTYPE *loc, struct parse_params *p, const char *message);
          }
          #{'%lexer-context BEG "a"' if operand == :alias_before}
          %token A "a" B
          #{patterns ? "%token-pattern A /a/\n%token-pattern B /b/" : ''}
          #{operand == :identifier ? '%lexer-context BEG A' : '%lexer-context BEG "a"' unless operand == :alias_before}
          %lexer-context END B
          #{(2...64).map { |i| "%lexer-context C#{i} A" }.join("\n")}
          %%
          start: A B;
          %%
          int yyerror(YYLTYPE *loc, struct parse_params *p, const char *message)
          {
            (void)loc; (void)p; (void)message;
            return 0;
          }
        GRAMMAR
        File.write(lexer, <<~C_CODE)
          #include "parser.h"
          #include "parser.h"

          int yylex(YYSTYPE *value, struct parse_params *p)
          {
            (void)value;
            switch (p->reads++) {
            case 0: return A;
            case 1:
              if (!yy_lexer_context_is(p->current_state, YY_CTX_BEG)
                  || !yy_lexer_context_is(p->current_state, YY_CTX_C63)
                  || yy_lexer_context_is(p->current_state, YY_CTX_END))
                return YYUNDEF;
              return B;
            default: return YYEOF;
            }
          }

          int main(void)
          {
            struct parse_params params = { 0, 0 };
            if (yy_lexer_context_is(-1, YY_CTX_BEG)) return 1;
            if (yyparse(&params)) return 2;
            return params.reads != 3;
          }
        C_CODE
        Lrama::Command.new(["-d", "-o", output, grammar]).run
        _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, lexer, "-o", executable)
        expect(status.success?).to be(true), err
        _out, err, status = Open3.capture3(executable)
        expect(status.success?).to be(true), err
      end
    end
  end
end
