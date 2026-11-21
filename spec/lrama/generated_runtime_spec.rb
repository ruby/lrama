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

  %w[ielr canonical-lr].each do |tables|
    it "selects the end token after a nonassociative expression with #{tables} tables" do
      with_parser(<<~GRAMMAR) do |parser|
        %define lr.type pslr
        %define pslr.tables #{tables}
        %define api.pslr.lexer generated
        %token-pattern A /a/
        %token-pattern OP /o/
        %token-pattern END /o/
        %lex-prec END <- OP
        %nonassoc OP
        %%
        start: expr END;
        expr: A | expr OP expr;
        %%
        int main(void) { yypslr_set_input("aoao", 4); return yyparse(); }
      GRAMMAR
        _out, err, status = Open3.capture3(parser)
        expect(status.exitstatus).to eq(0), err
      end
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

  it "preserves the outer scanner across nested parses from token and grammar actions" do
    with_parser(<<~'GRAMMAR') do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %define api.pure full
      %locations
      %code provides {
        #include <stdlib.h>
        #define YYPSLR_LAYOUT_BUFFER_SIZE 2
      }
      %token-pattern A /a/
      %token-pattern B /b/
      %token-pattern YYLAYOUT_WS /[ \n]+/
      %token-action A {
        int length = YYPSLR_LAYOUT_LENGTH;
        const char *layout = length == 2 ? "  " : "\n  ";
        yypslr_set_input("   b", 4);
        if (yyparse() || YYPSLR_LAYOUT_LENGTH != length
            || strcmp(YYPSLR_LAYOUT_TEXT, layout)) exit(2);
      }
      %%
      start: prefix A {
        if (@2.first_line != 2 || @2.first_column != 3 || @2.last_column != 4) YYABORT;
      } | B;
      prefix: A {
        yypslr_set_input("b", 1);
        if (yyparse() || @1.first_line != 1 || @1.first_column != 3) YYABORT;
      };
      %%
      int main(void) {
        YYSTYPE value;
        YYLTYPE loc;
        yypslr_set_input("  a\n  a", 7);
        if (yyparse()) return 3;
        yypslr_set_input("  a", 3);
        if (yylex(&value, &loc) != A || loc.first_column != 3 || loc.last_column != 4) return 4;
        return yylex(&value, &loc) != YYEOF;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end

  it "keeps scanner state independent while two threads are inside yyparse" do
    skip "requires pthreads" if windows?
    with_parser(<<~GRAMMAR, flags: ["-pthread"]) do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %define api.pure full
      %parse-param {int expected}
      %code provides {
        #include <pthread.h>
        #define yyerror(Loc, Expected, Message) yyerror(Loc, Message)
        static pthread_t thread;
        static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
        static pthread_cond_t changed = PTHREAD_COND_INITIALIZER;
        static int phase;
        static void enter_phase(int next_phase) {
          pthread_mutex_lock(&mutex);
          while (phase < next_phase - 1) pthread_cond_wait(&changed, &mutex);
          phase = next_phase;
          pthread_cond_broadcast(&changed);
          pthread_mutex_unlock(&mutex);
        }
      }
      %initial-action {
        if (expected == B) {
          enter_phase(1);
          enter_phase(4);
        } else {
          enter_phase(3);
          if (pthread_join(thread, 0)) YYABORT;
        }
      }
      %token-pattern A /a/
      %token-pattern B /b/
      %%
      start: A { if (expected != A) YYABORT; } | B { if (expected != B) YYABORT; };
      %%
      static void *worker(void *result) {
        yypslr_set_input("b", 1);
        *(int *)result = yyparse(B);
        return 0;
      }
      int main(void) {
        int result;
        yypslr_set_input("a", 1);
        if (pthread_create(&thread, 0, worker, &result)) return 1;
        enter_phase(2);
        return yyparse(A) || result;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end

  it "allows an initial action to set the generated lexer's input" do
    with_parser(<<~GRAMMAR) do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %initial-action { yypslr_set_input("a", 1); }
      %token-pattern A /a/
      %%
      start: A;
      %%
      int main(void) { return yyparse(); }
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
            return #{custom_copy ? 'copy_count != 0' : '0'};
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

  it "clears layout text for adjacent tokens and EOF and after replacing input" do
    with_parser(<<~'GRAMMAR') do |parser|
      %code provides { #include <stdio.h> }
      %define lr.type pslr
      %define api.pslr.lexer generated
      %token-pattern A /a/
      %token-pattern B /b/
      %token-pattern YYLAYOUT_WS / +/
      %token-action A { printf("A %d:[%s]\n", YYPSLR_LAYOUT_LENGTH, YYPSLR_LAYOUT_TEXT); }
      %token-action B { printf("B %d:[%s]\n", YYPSLR_LAYOUT_LENGTH, YYPSLR_LAYOUT_TEXT); }
      %token-action YYEOF { printf("EOF %d:[%s]\n", YYPSLR_LAYOUT_LENGTH, YYPSLR_LAYOUT_TEXT); }
      %%
      start: A B;
      %%
      int main(void) {
        yypslr_set_input(" ab", 3);
        if (yyparse()) return 1;
        yypslr_set_input("a b ", 4);
        return yyparse();
      }
    GRAMMAR
      out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
      expect(out).to eq("A 1:[ ]\nB 0:[]\nEOF 0:[]\nA 0:[]\nB 1:[ ]\nEOF 1:[ ]\n")
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

  [false, true].each do |scanner|
    it "runs the EOF action for an empty input pointer #{scanner ? 'with' : 'without'} scanner tables" do
      with_parser(<<~GRAMMAR) do |parser|
        %code provides { static int eof_count = 0; }
        %define lr.type pslr
        %define api.pslr.lexer generated
        #{'%token-pattern A /a/' if scanner}
        %token-action YYEOF { eof_count++; }
        %%
        start: %empty;
        %%
        int main(void) {
        #ifdef YYPSLR_ENABLED
          yypslr_scan_result result;
          if (yy_pseudo_scan_result(0, 0, 1, &result) != YYEMPTY
              || yy_pseudo_scan_result(-1, 0, 0, &result) != YYEMPTY) return 2;
        #endif
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

  it "consumes an explicit end marker before parsing the next record" do
    with_parser(<<~'GRAMMAR') do |parser|
      %define lr.type pslr
      %define api.pslr.lexer generated
      %code provides {
        #include <stdlib.h>
      }
      %token END 0
      %token-pattern END /;/
      %token-pattern A /a/
      %token-action END { if (yyleng != 1) exit(3); }
      %%
      start: A;
      %%
      int main(void) {
        yypslr_set_input("a;a;", 4);
        return yyparse() || yyparse();
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end
end
