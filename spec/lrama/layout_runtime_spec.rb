# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "PSLR layout storage" do
  def with_parser(source)
    Dir.mktmpdir("lrama-layout") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, <<~GRAMMAR + source)
        %define lr.type pslr
        %define api.pslr.lexer generated
        %code provides {
          #include <string.h>
          #include <stdlib.h>
          static int yyerror(YYLTYPE *loc, const char *message)
          { (void)loc; (void)message; return 0; }
        }
      GRAMMAR
      Lrama::Command.new(["-o", output, grammar]).run
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
      expect(status.success?).to be(true), err
      yield executable
    end
  end

  [false, true].each do |actions|
    it "accepts layout beyond the initial buffer #{actions ? 'with' : 'without'} token actions" do
      with_parser(<<~GRAMMAR) do |parser|
        %define parse.lac none
        %code provides {
          #define YYSTACK_USE_ALLOCA 1
          static int expected;
          static int invalid_layout;
        }
        %token-pattern A /a/
        %token-pattern YYLAYOUT_WS / +/
        %token-pattern YYLAYOUT_COMMENT /!+/
        #{actions ? <<~ACTIONS : ''}
          %token-action A {
            if (YYPSLR_LAYOUT_LENGTH != expected
                || strlen(YYPSLR_LAYOUT_TEXT) != (size_t)expected)
              invalid_layout = 1;
          }
          %token-action YYEOF {
            if (YYPSLR_LAYOUT_LENGTH || YYPSLR_LAYOUT_TEXT[0]) invalid_layout = 1;
          }
        ACTIONS
        %%
        start: A;
        %%
        int main(int argc, char **argv) {
          if (argc != 2) return 1;
          expected = (int)strlen(argv[1]) - 1;
          yypslr_set_input(argv[1], strlen(argv[1]));
          if (yyparse() || invalid_layout) return 2;
          expected = 0;
          yypslr_set_input("a", 1);
          return yyparse() || invalid_layout;
        }
      GRAMMAR
        [" " * 4095, " " * 4096, " " * 32768, " !" * 8192].each do |layout|
          _out, err, status = Open3.capture3(parser, layout + "a")
          expect(status.success?).to be(true), "#{layout.bytesize} bytes: exit #{status.exitstatus}: #{err}"
        end
      end
    end
  end

  it "preserves long trailing layout for the EOF action and clears it when input is replaced" do
    with_parser(<<~GRAMMAR) do |parser|
      %code provides { static int trailing_length; }
      %token-pattern A /a/
      %token-pattern YYLAYOUT_WS / +/
      %token-action YYEOF {
        trailing_length = YYPSLR_LAYOUT_LENGTH;
        if (strlen(YYPSLR_LAYOUT_TEXT) != (size_t)trailing_length) abort();
      }
      %%
      start: A;
      %%
      int main(void) {
        char input[8194];
        input[0] = 'a';
        memset(input + 1, ' ', 8192);
        input[8193] = 0;
        yypslr_set_input(input, 8193);
        if (yyparse() || trailing_length != 8192) return 1;
        yypslr_set_input("a", 1);
        if (YYPSLR_LAYOUT_LENGTH || YYPSLR_LAYOUT_TEXT[0]) return 2;
        return yyparse() || trailing_length;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end

  it "preserves accumulated text on allocation failure and releases grown storage on clear" do
    with_parser(<<~GRAMMAR) do |parser|
      %define parse.lac none
      %code provides {
        #include <limits.h>
        #define YYPSLR_LAYOUT_BUFFER_SIZE 4
        static int fail_allocation;
        static int allocations;
        static int releases;
        #define YYMALLOC(Size) (fail_allocation ? 0 : (allocations++, malloc(Size)))
        #define YYFREE(Ptr) (releases++, free(Ptr))
      }
      %token-pattern A /a/
      %token-pattern YYLAYOUT_WS / +/
      %%
      start: A;
      %%
      int main(void) {
        if (!YYPSLR_LAYOUT_APPEND("  ", 2)) return 1;
        if (YYPSLR_LAYOUT_APPEND("", -1) || YYPSLR_LAYOUT_APPEND("", INT_MAX)) return 2;
        fail_allocation = 1;
        if (YYPSLR_LAYOUT_APPEND("!!!", 3)) return 3;
        if (YYPSLR_LAYOUT_LENGTH != 2 || strcmp(YYPSLR_LAYOUT_TEXT, "  ")) return 4;
        fail_allocation = 0;
        if (!YYPSLR_LAYOUT_APPEND("!!!", 3)) return 5;
        if (YYPSLR_LAYOUT_LENGTH != 5 || strcmp(YYPSLR_LAYOUT_TEXT, "  !!!")) return 6;
        YYPSLR_LAYOUT_CLEAR();
        if (allocations != 1 || releases != 1 || YYPSLR_LAYOUT_TEXT[0]) return 7;
        fail_allocation = 1;
        yypslr_set_input("    a", 5);
        return yyparse() != 1;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end
end
