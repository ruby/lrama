# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "PSLR downstream scanner compatibility" do
  include PslrFamilyHelper

  it "uses the initial state's nullable prefix to select the scanner token" do
    grammar = build_grammar(<<~GRAMMAR, "initial_nullable_prefix.y")
      %define lr.type pslr
      %token-pattern IF /if/
      %token-pattern ID /[a-z]+/
      %lex-prec ID <~ IF
      %%
      start: optional ID;
      optional: %empty;
    GRAMMAR
    _ielr_states, pslr_states = compute_ielr_and_pslr(grammar)
    scanner = pslr_states.scanner_fsa
    accepting_state = "if".each_char.reduce(scanner.initial_state) do |state, char|
      scanner.states.fetch(state.transitions.fetch(char))
    end

    expect(pslr_states.scanner_accepts_table[0, accepting_state.id]&.name).to eq("ID")
  end

  it "merges compatible contexts and propagates late lookaheads through every successor" do
    grammar = build_grammar(<<~GRAMMAR, "compatible_successors.y")
      %define lr.type pslr
      %token-pattern P /p/
      %token-pattern Q /q/
      %token-pattern R /r/
      %token-pattern X /x/
      %token-pattern Y /y/
      %token-pattern Z /z/
      %token-pattern A /a/
      %token-pattern B /b/
      %%
      start: P shared A | Q R shared B;
      shared: X Y | X Z;
    GRAMMAR
    ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

    expect(pslr_states.states_count).to eq(ielr_states.states_count)
    %w[Y Z].each do |suffix|
      reductions = pslr_states.states.select do |state|
        state.reduces.any? { |reduce| reduce.rule.display_name == "shared -> X #{suffix}" }
      end
      expect(reductions.size).to eq(1)
      expect(acceptable_tokens(pslr_states, reductions.first)).to contain_exactly("A", "B")
    end
  end

  {
    "two shifts" => ["shared: X Y;", "x y"],
    "four shifts" => ["shared: X Y X Y;", "x y x y"],
    "right recursion" => ["shared: X shared | Y;", "x x y"],
    "left recursion" => ["shared: shared X | Y;", "y x x"],
    "nullable recursion" => ["shared: X optional Y; optional: %empty | X optional;", "x x x y"],
    "nullable tail" => ["shared: X optional; optional: %empty;", "x"],
    "recursive nullable tail" => ["shared: X optional; optional: %empty | Y optional;", "x y y"]
  }.each do |label, (rules, shared_input)|
    it "preserves keyword and identifier contexts through #{label}" do
      Dir.mktmpdir("lrama-downstream") do |dir|
        compiler = ENV.fetch("COMPILER", "cc")
        cpp = compiler.include?("++")
        grammar = File.join(dir, "parser.y")
        output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
        executable = File.join(dir, "parser")
        File.write(grammar, <<~GRAMMAR)
          %code provides {
            #include <string.h>
            static int yyerror(YYLTYPE *loc, const char *message)
            {
              (void)loc;
              (void)message;
              return 0;
            }
          }
          %define lr.type pslr
          %define api.pslr.lexer generated
          %token-pattern P /p/
          %token-pattern Q /q/
          %token-pattern X /x/
          %token-pattern Y /y/
          %token-pattern IF /if/
          %token-pattern ID /[a-z]+/
          %token-pattern YYLAYOUT_WS /[ ]+/
          %lex-prec ID <~ IF
          %lex-prec ID <~ X
          %lex-prec ID <~ Y
          %%
          start: P shared IF | Q shared ID;
          #{rules}
          %%
          int main(int argc, char **argv) {
            if (argc != 2) return 2;
            yypslr_set_input(argv[1], (int)strlen(argv[1]));
            return yyparse();
          }
        GRAMMAR
        Lrama::Command.new(["-o", output, grammar]).run
        _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
        expect(status.success?).to be(true), err

        ["q #{shared_input} if", "p #{shared_input} if", "q #{shared_input} name"].each do |input|
          _out, err, status = Open3.capture3(executable, input)
          expect(status.success?).to be(true), "rejected #{input.inspect}: #{err}"
        end
        _out, _err, status = Open3.capture3(executable, "p #{shared_input} name")
        expect(status.exitstatus).to eq(1)
      end
    end
  end
end
