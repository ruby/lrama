# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "LAC runtime" do
  def with_lac_parser(source, instrument: false, flags: [])
    Dir.mktmpdir("lrama-lac") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, <<~GRAMMAR + source)
        %define parse.lac full
        %code provides {
          static int yyerror(YYLTYPE *loc, const char *message)
          { (void)loc; (void)message; return 0; }
        }
      GRAMMAR
      Lrama::Command.new(["-o", output, grammar]).run
      if instrument
        code = File.read(output)
        expect(code.sub!(/(yy_lac_check_ \([^\n]*\)\n\{)/, "\\1\n  if (yytoken == YYSYMBOL_YYEOF) eof_checks++;")).not_to be_nil
        File.write(output, code)
      end
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", *flags, output, "-o", executable)
      expect(status.success?).to be(true), err
      yield executable
    end
  end

  it "does not copy the parser stack or repeatedly validate unchanged lookahead" do
    with_lac_parser(<<~'GRAMMAR', instrument: true) do |parser|
      %code provides {
        #include <stdlib.h>
        #include <string.h>
        #include <stdio.h>
        #define YYINITDEPTH 2048
        static long copied_states = 0, allocations = 0, eof_checks = 0;
        #define YYCOPY(Dst, Src, Count) (copied_states += (Count), memcpy((Dst), (Src), (Count) * sizeof(*(Src))))
        #define YYMALLOC(Size) (allocations++, malloc(Size))
        static int remaining;
      }
      %token A
      %code provides {
        static int yylex(YYSTYPE *value)
        { (void)value; return remaining-- > 0 ? A : YYEOF; }
      }
      %%
      start: list;
      list: %empty | A list;
      %%
      int main(void) {
        int lengths[] = {256, 1024};
        int i;
        for (i = 0; i < 2; i++) {
          copied_states = allocations = eof_checks = 0;
          remaining = lengths[i];
          if (yyparse()) return 1;
          printf("%ld %ld %ld\n", copied_states, allocations, eof_checks);
        }
        return 0;
      }
    GRAMMAR
      out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
      expect(out).to eq("0 0 1\n0 0 1\n")
    end
  end

  it "revalidates lookahead changed by a semantic action before further reductions" do
    with_lac_parser(<<~'GRAMMAR') do |parser|
      %code provides { static int reduced = 0; }
      %token A B C
      %code provides {
        static int yylex(YYSTYPE *value) {
          static int tokens[] = {A, B, YYEOF};
          static int i = 0;
          (void)value;
          return tokens[i++];
        }
      }
      %%
      start: mid B;
      mid: prefix { reduced++; };
      prefix: A { yychar = C; };
      %%
      int main(void) { return yyparse() == 1 && reduced == 0 ? 0 : 1; }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "revalidates a new lookahead after yyclearin even when its token kind is unchanged" do
    with_lac_parser(<<~'GRAMMAR', instrument: true) do |parser|
      %code provides { static int eof_checks = 0; }
      %token A
      %code provides {
        static int yylex(YYSTYPE *value) {
          static int i = 0;
          (void)value;
          return i++ ? YYEOF : A;
        }
      }
      %%
      start: n;
      n: A { yyclearin; };
      %%
      int main(void) { return yyparse() || eof_checks != 2; }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "revalidates YYBACKUP after it changes the stack while keeping the same lookahead kind" do
    with_lac_parser(<<~'GRAMMAR', instrument: true) do |parser|
      %code provides { static int eof_checks = 0, backed_up = 0, reduced = 0; }
      %token A
      %code provides {
        static int yylex(YYSTYPE *value) {
          static int i = 0;
          (void)value;
          return i++ ? YYEOF : A;
        }
      }
      %%
      start: n;
      n: A {
        if (!backed_up) {
          backed_up = 1;
          yyclearin;
          YYBACKUP(YYEOF, 0);
        }
        reduced++;
      }
      | %empty { reduced++; };
      %%
      int main(void) { return yyparse() || !backed_up || reduced != 1 || eof_checks != 2; }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "grows speculative storage without changing the parser stack and reports allocation failure" do
    with_lac_parser(<<~'GRAMMAR', flags: ["-DYYINITDEPTH=2"]) do |parser|
      %code provides {
        #include <stdlib.h>
        #include <string.h>
        static int allocations = 0, releases = 0, copies = 0, fail = 0, reduced = 0;
        #define YYMALLOC(Size) (fail ? 0 : (allocations++, malloc(Size)))
        #define YYFREE(Ptr) (releases++, free(Ptr))
        #define YYCOPY(Dst, Src, Count) (copies++, memcpy((Dst), (Src), (Count) * sizeof(*(Src))))
      }
      %token A
      %code provides {
        static int yylex(YYSTYPE *value) {
          static int i = 0;
          (void)value;
          return i++ ? YYEOF : A;
        }
      }
      %%
      start: n n n n n A;
      n: %empty { reduced++; };
      %%
      int main(void) {
        yy_state_t stack[] = {0};
        if (yy_lac_check_(stack, stack, YYSYMBOL_A) != 1) return 1;
        if (!allocations || !copies || allocations != releases || stack[0] || reduced) return 2;
        fail = 1;
        if (yy_lac_check_(stack, stack, YYSYMBOL_A) != YYENOMEM) return 3;
        if (stack[0] || reduced) return 4;
        fail = 0;
        if (yyparse() || reduced != 5) return 5;
        return 0;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end

  it "respects YYMAXDEPTH when empty reductions grow the speculative stack" do
    with_lac_parser(<<~'GRAMMAR', flags: ["-DYYMAXDEPTH=4"]) do |parser|
      %token A
      %code provides {
        static int yylex(YYSTYPE *value) { (void)value; return YYEOF; }
      }
      %%
      start: n n n n n A;
      n: %empty;
      %%
      int main(void) {
        yy_state_t stack[] = {0};
        return yy_lac_check_(stack, stack, YYSYMBOL_A) == YYENOMEM && stack[0] == 0 ? 0 : 1;
      }
    GRAMMAR
      _out, err, status = Open3.capture3(parser)
      expect(status.success?).to be(true), err
    end
  end
end
