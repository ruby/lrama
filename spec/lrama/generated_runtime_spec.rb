# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "generated runtime" do
  def with_parser(source, flags: [])
    Dir.mktmpdir("lrama-runtime") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, <<~GRAMMAR + source)
        %code provides {
          static int yyerror(YYLTYPE *loc, const char *message)
          {
            (void)loc;
            (void)message;
            return 0;
          }
        }
      GRAMMAR
      Lrama::Command.new(["-o", output, grammar]).run
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", *flags, output, "-o", executable)
      expect(status.success?).to be(true), err
      yield executable
    end
  end

  it "compiles PSLR scanning without user-provided string declarations or layout tokens" do
    with_parser(<<~GRAMMAR) do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %token-pattern A /a/
      %%
      start: A;
      %%
      int main(void) { yypslr_set_input("a", 1); return yyparse(); }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  ["lalr", "pslr"].each do |type|
    it "uses heap storage for LAC with #{type} and an alloca parser stack" do
      lexer = type == "pslr" ? "%define api.pslr.lexer generated" : <<~GRAMMAR
        %code provides {
          static int yylex(YYSTYPE *value)
          {
            static int read = 0;
            (void)value;
            return read++ ? YYEOF : A;
          }
        }
      GRAMMAR
      with_parser(<<~GRAMMAR, flags: ["-DYYSTACK_USE_ALLOCA=1"]) do |parser|
        %code provides { #include <string.h> }
        %define lr.type #{type}
        %define parse.lac full
        #{lexer}
        %token-pattern A /a/
        %%
        start: A;
        %%
        int main(void) {
          #{type == "pslr" ? 'yypslr_set_input("a", 1);' : ""}
          return yyparse();
        }
      GRAMMAR
        _out, err, status = Open3.capture3(parser)
        expect(status.success?).to be(true), err
      end
    end

    [false, true].each do |custom_copy|
      it "supports yyoverflow with #{type} LAC#{custom_copy ? ' and a custom YYCOPY' : ''}" do
        lexer = type == "pslr" ? "%define api.pslr.lexer generated" : <<~GRAMMAR
          %define parse.lac full
          %code provides {
            static int yylex(YYSTYPE *value)
            {
              static int read = 0;
              (void)value;
              return read++ ? YYEOF : A;
            }
          }
        GRAMMAR
        copy = custom_copy ? <<~GRAMMAR : ""
          #include <string.h>
          static int copy_count = 0;
          #define YYCOPY(Dst, Src, Count) (copy_count++, memcpy((Dst), (Src), (Count) * sizeof(*(Src))))
        GRAMMAR
        with_parser(<<~GRAMMAR) do |parser|
          %code provides {
            #define yyoverflow(Message, States, StatesSize, Values, ValuesSize, Locations, LocationsSize, StackSize) ((void)0)
            #{copy}
          }
          %define lr.type #{type}
          #{lexer}
          %token-pattern A /a/
          %%
          start: A;
          %%
          int main(void) {
            #{type == "pslr" ? 'yypslr_set_input("a", 1);' : ""}
            if (yyparse()) return 1;
            return #{custom_copy ? 'copy_count == 0' : '0'};
          }
        GRAMMAR
          _out, err, status = Open3.capture3(parser)
          expect(status.success?).to be(true), err
        end
      end
    end
  end

  it "tracks token, layout and EOF locations and resets them when input is replaced" do
    with_parser(<<~'GRAMMAR') do |parser|
      %code provides {
        #include <stdio.h>
        #include <string.h>
      }
      %define lr.type pslr
      %define api.pslr.lexer generated
      %locations
      %token-pattern A /a+/
      %token-pattern YYLAYOUT_WS /[ \t\r\n]+/
      %%
      start: A A {
        printf("%d:%d-%d:%d %d:%d-%d:%d\n",
               @1.first_line, @1.first_column, @1.last_line, @1.last_column,
               @2.first_line, @2.first_column, @2.last_line, @2.last_column);
      };
      %%
      int main(void) {
        YYSTYPE value = 0;
        YYLTYPE location;
        yypslr_set_input(" \naa\n a \n", 9);
        if (yyparse()) return 1;
        if (yylex(&value, &location) != YYEOF) return 2;
        printf("EOF %d:%d-%d:%d\n", location.first_line, location.first_column,
               location.last_line, location.last_column);
        yypslr_set_input("a aa", 4);
        return yyparse();
      }
    GRAMMAR
      out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
      expect(out).to eq("2:1-2:3 3:2-3:3\nEOF 4:1-4:1\n1:1-1:2 1:3-1:5\n")
    end
  end

  it "preserves the ninth and sixty-fourth lexer context flags" do
    declarations = (0...64).map { |i| "%lexer-context C#{i} A" }.join("\n")
    with_parser(<<~GRAMMAR) do |parser|
      %code provides { #include <string.h> }
      %define lr.type pslr
      %define api.pslr.lexer generated
      %token-pattern A /a/
      #{declarations}
      %%
      start: A;
      %%
      int main(void) {
        int state;
        int found = 0;
        for (state = 0; state < YYNSTATES; state++) {
          if (yy_lexer_context_is(state, YY_CTX_C8) && yy_lexer_context_is(state, YY_CTX_C63))
            found = 1;
        }
        if (!found || yy_lexer_context_is(-1, YY_CTX_C63)
            || yy_lexer_context_is(YYNSTATES, YY_CTX_C63)) return 1;
        yypslr_set_input("a", 1);
        return yyparse();
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "generates an EOF lexer with locations for an empty token universe and consumes unexpected bytes" do
    with_parser(<<~GRAMMAR) do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %locations
      %%
      start: %empty;
      %%
      int main(void) {
        YYSTYPE value = 0;
        YYLTYPE location;
        yypslr_set_input("", 0);
        if (yyparse()) return 1;
        yypslr_set_input("x", 1);
        if (!yyparse()) return 2;
        yypslr_set_input("x", 1);
        if (yylex(&value, &location) != YYUNDEF) return 3;
        if (location.first_column != 1 || location.last_column != 2) return 4;
        if (yylex(&value, &location) != YYEOF) return 5;
        if (location.first_column != 2 || location.last_column != 2) return 6;
        yypslr_set_input("", 0);
        return yyparse();
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "runs the EOF token action without token patterns or locations" do
    with_parser(<<~GRAMMAR) do |parser|
      %code provides { static int eof_count = 0; }
      %define lr.type pslr
      %define api.pslr.lexer generated
      %token-action YYEOF { eof_count++; }
      %%
      start: %empty;
      %%
      int main(void) {
        yypslr_set_input(0, 0);
        if (yyparse() || eof_count != 1) return 1;
        yypslr_set_input("", 0);
        return yyparse() || eof_count != 2;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  [false, true].each do |scanner|
    it "uses a renamed EOF token and its action #{scanner ? 'with scanner and layout' : 'without token patterns'}" do
      patterns = scanner ? "%token-pattern A /a/\n%token-pattern YYLAYOUT_WS / +/" : ""
      with_parser(<<~GRAMMAR) do |parser|
        %code provides { static int eof_count = 0; static int trailing_layout = 0; }
        %define lr.type pslr
        %define api.pslr.lexer generated
        %token EOI 0
        %token-action EOI { eof_count++; trailing_layout = YYPSLR_LAYOUT_LENGTH; }
        #{patterns}
        %%
        start: #{scanner ? 'A' : '%empty'};
        %%
        int main(void) {
          yypslr_set_input("#{scanner ? 'a  ' : ''}", #{scanner ? 3 : 0});
          return yyparse() || eof_count != 1 || trailing_layout != #{scanner ? 2 : 0};
        }
      GRAMMAR
        _out, err, status = Open3.capture3(parser)
        expect(status.success?).to be(true), err
      end
    end
  end
end
