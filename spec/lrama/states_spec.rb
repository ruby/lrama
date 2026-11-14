# frozen_string_literal: true

RSpec.describe Lrama::States do
  describe 'shared items' do
    it 'reuses each rule and position across closures, transitions, and split states' do
      path = "integration/ielr.y"
      grammar = Lrama::Parser.new(File.read(fixture_path(path)), path).parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      items = states.states.flat_map do |state|
        state.items + state.transitions.flat_map(&:to_items) + state.lane_items.values.flatten
      end
      groups = items.group_by { |item| [item.rule.object_id, item.position] }
      expect(groups.values.map { |group| group.map(&:object_id).uniq.length }.uniq).to eq([1])
      expect(states.states_count).to eq(22)
    end

    it 'keeps equal rules and separate grammar instances distinct' do
      items = 2.times.map do
        grammar = Lrama::Parser.new("%%\nstart: 'a' | 'a';\n", "duplicate.y").parse
        grammar.prepare
        states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.states.first.closure
      end

      expect(items.map { |group| group.map(&:rule_id) }).to eq([[1, 2], [1, 2]])
      expect(items.flatten.map(&:object_id).uniq.length).to eq(4)
    end
  end

  describe '#nterm_transitions' do
    let(:states) do
      path = "integration/ielr.y"
      grammar = Lrama::Parser.new(File.read(fixture_path(path)), path).parse
      grammar.prepare
      described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    end

    it 'reuses the list in state and transition order while the graph is unchanged' do
      states.compute
      transitions = states.send(:nterm_transitions)

      expect(transitions.map(&:object_id)).to eq(states.states.flat_map(&:nterm_transitions).map(&:object_id))
      expect(states.send(:nterm_transitions).object_id).to eq(transitions.object_id)
    end

    it 'replaces an empty list queried before LR0 construction' do
      expect(states.send(:nterm_transitions)).to eq([])

      states.compute

      transitions = states.send(:nterm_transitions)
      expect(transitions).not_to be_empty
      expect(transitions.map(&:object_id)).to eq(states.states.flat_map(&:nterm_transitions).map(&:object_id))
    end

    it 'rebuilds the list after splitting adds states and redirects transitions' do
      states.compute
      original_count = states.states_count
      original = states.send(:nterm_transitions)

      states.compute_ielr

      transitions = states.send(:nterm_transitions)
      expect(states.states_count).to be > original_count
      expect(transitions.object_id).not_to eq(original.object_id)
      expect(transitions.map(&:object_id)).to eq(states.states.flat_map(&:nterm_transitions).map(&:object_id))
      expect(states.send(:nterm_transitions).object_id).to eq(transitions.object_id)
    end
  end

  describe '#bitmap_to_terms' do
    let(:grammar) do
      grammar = Lrama::Parser.new("%%\nstart: 'a' 'b';\n", "bitmap.y").parse
      grammar.prepare
      grammar
    end
    let(:states) { described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new)) }
    let(:terms) { grammar.terms.last(2) }
    let(:bitmap) { Lrama::Bitmap.from_array(terms.map(&:number).reverse) }

    it 'shares a frozen array for the same bitmap in symbol number order' do
      converted = states.send(:bitmap_to_terms, bitmap)

      expect(converted).to eq(terms)
      expect(states.send(:bitmap_to_terms, bitmap)).to equal(converted)
      expect(converted).to be_frozen
      expect { converted << grammar.eof_symbol }.to raise_error(FrozenError)
    end

    it 'shares a frozen empty array for an empty bitmap' do
      converted = states.send(:bitmap_to_terms, 0)

      expect(converted).to eq([])
      expect(states.send(:bitmap_to_terms, 0)).to equal(converted)
      expect(converted).to be_frozen
    end

    it 'keeps symbols from separate grammars isolated' do
      other_grammar = Lrama::Parser.new("%%\nstart: 'x' 'y';\n", "other.y").parse
      other_grammar.prepare
      other_states = described_class.new(other_grammar, Lrama::Tracer.new(Lrama::Logger.new))

      expect(states.send(:bitmap_to_terms, bitmap)).to eq(terms)
      expect(other_states.send(:bitmap_to_terms, bitmap)).to eq(other_grammar.terms.last(2))
      expect(other_states.send(:bitmap_to_terms, bitmap).first).not_to equal(terms.first)
    end

    it 'retains conversions when lookahead sets are rebuilt for the same grammar' do
      converted = states.send(:bitmap_to_terms, bitmap)
      states.send(:clear_look_ahead_sets)

      expect(states.send(:bitmap_to_terms, bitmap)).to equal(converted)
    end
  end

  describe '#compute_goto_follows' do
    it 'reuses always-follow bitmaps without converting symbol arrays back to bitmaps' do
      path = "integration/ielr.y"
      grammar = Lrama::Parser.new(File.read(fixture_path(path)), path).parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.send(:compute_predecessors)
      bitmaps = states.send(:compute_always_follows).freeze
      expect(Lrama::Bitmap).not_to receive(:from_array)

      states.send(:compute_goto_follows, bitmaps)

      bitmaps.each do |goto, bitmap|
        always_follows = goto.from_state.always_follows.fetch(goto)
        expect(always_follows).to eq(bitmap)
        expect(always_follows & ~goto.from_state.goto_follows.fetch(goto)).to eq(0)
      end
    end
  end

  describe 'IELR lookahead bitmaps' do
    it 'splits states with token numbers above the machine word size' do
      padding = 128.times.map { |i| "PADDING_#{i}" }.join(' ')
      source = File.read(fixture_path("integration/ielr.y")).sub("%token a", "%token #{padding}\n%token a")
      grammar = Lrama::Parser.new(source, "bitmap.y").parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      expect(states.states_count).to eq(22)
      expect(states.sr_conflicts_count).to eq(0)
      expect(states.rr_conflicts_count).to eq(0)
      lookaheads = states.states.flat_map { |state| state.item_lookahead_set.values }
      expect(lookaheads.all? { |lookahead| lookahead.is_a?(Integer) }).to be(true)
      expect(lookaheads.max.bit_length).to be > 128
      expect { Lrama::Context.new(states) }.not_to raise_error
    end
  end

  describe 'IELR lookaheads from multiple predecessors' do
    let(:source) { File.read(fixture_path("ielr/multiple_predecessor_lookaheads.y")) }

    it 'splits long rules without exhausting the Ruby stack' do
      rhs = Array.new(3_000, "'x'").join(' ')
      grammar = Lrama::Parser.new(source.gsub("'x' 'y'", rhs), "long.y").parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      states.compute_ielr

      expect(states.sr_conflicts_count).to eq(0)
      expect(states.rr_conflicts_count).to eq(0)
      expect { Lrama::Context.new(states) }.not_to raise_error
    end

    [false, true].each do |reverse|
      it "unions every predecessor's goto follows with reverse order #{reverse}" do
        grammar = Lrama::Parser.new(source, "lookaheads.y").parse
        grammar.prepare
        states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.send(:compute_predecessors)
        states.send(:compute_follow_kernel_items)
        always_follows = states.send(:compute_always_follows)
        states.send(:compute_goto_follows, always_follows)
        target = states.states.find { |state| state.kernels.any? { |item| item.lhs.name == "left" && item.position == 1 } }
        target.predecessors.reverse! if reverse

        lookaheads = target.kernels.map do |item|
          Lrama::Bitmap.to_array(target.item_lookahead_set.fetch(item)).map { |number| grammar.find_symbol_by_number!(number).name }
        end

        expect(lookaheads).to eq([["'d'", "'e'"], ["'d'", "'e'"]])
      end
    end

    ["'x'", "'x' 'y'", "'x' 'y' 'z'"].each do |rhs|
      it "splits reductions with the shared RHS #{rhs} without conflicts" do
        grammar = Lrama::Parser.new(source.gsub("'x' 'y'", rhs), "lookaheads.y").parse
        grammar.prepare
        states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        states.compute_ielr

        expect(states.sr_conflicts_count).to eq(0)
        expect(states.rr_conflicts_count).to eq(0)
        expect { Lrama::Context.new(states) }.not_to raise_error
      end
    end
  end

  describe 'IELR lookaheads through nested rules' do
    ["'y'", "'y' 'z'", "'y' 'z' 'w'"].each do |rhs|
      it "splits nested reductions with the shared tail #{rhs} without conflicts" do
        source = File.read(fixture_path("ielr/nested_rule_contributions.y")).gsub("'y'", rhs)
        grammar = Lrama::Parser.new(source, "nested.y").parse
        grammar.prepare
        states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        states.compute_ielr

        expect(states.sr_conflicts_count).to eq(0)
        expect(states.rr_conflicts_count).to eq(0)
        expect { Lrama::Context.new(states) }.not_to raise_error
      end
    end
  end

  describe '#compute' do
    it "basic" do
      path = "common/basic.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(grammar: true, rules: true, terms: true, states: true, itemsets: true, lookaheads: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Rule Usage Frequency

            0 tSTRING (4 times)
            1 keyword_class (3 times)
            2 keyword_end (3 times)
            3 '+' (2 times)
            4 string (2 times)
            5 string_1 (2 times)
            6 '!' (1 times)
            7 '-' (1 times)
            8 '?' (1 times)
            9 EOI (1 times)
           10 class (1 times)
           11 program (1 times)
           12 string_2 (1 times)
           13 strings_1 (1 times)
           14 strings_2 (1 times)
           15 tNUMBER (1 times)


        1 Unused Rules

            0 unused


        19 Terms

        13 Non-Terminals

        11 Unused Terms

            0 YYerror
            1 YYUNDEF
            2 '\\\\'
            3 '\\13'
            4 keyword_class2
            5 tNUMBER
            6 tPLUS
            7 tMINUS
            8 tEQ
            9 tEQEQ
           10 '>'


        State 1 conflicts: 2 shift/reduce, 1 reduce/reduce


        Grammar

            0 $accept: program "EOI"

            1 program: class
            2        | '+' strings_1
            3        | '-' strings_2

            4 class: keyword_class tSTRING "end"

            5 $@1: ε

            6 $@2: ε

            7 class: keyword_class $@1 tSTRING '!' "end" $@2

            8 $@3: ε

            9 $@4: ε

           10 class: keyword_class $@3 tSTRING '?' "end" $@4

           11 strings_1: string_1

           12 strings_2: string_1
           13          | string_2

           14 string_1: string

           15 string_2: string '+'

           16 string: tSTRING

           17 unused: tNUMBER


        State 0

            0 $accept: • program "EOI"
            1 program: • class
            2        | • '+' strings_1
            3        | • '-' strings_2
            4 class: • keyword_class tSTRING "end"
            7      | • keyword_class $@1 tSTRING '!' "end" $@2
           10      | • keyword_class $@3 tSTRING '?' "end" $@4

            keyword_class  shift, and go to state 1
            '+'            shift, and go to state 2
            '-'            shift, and go to state 3

            program  go to state 4
            class    go to state 5


        State 1

            4 class: keyword_class • tSTRING "end"
            5 $@1: ε •  [tSTRING]
            7 class: keyword_class • $@1 tSTRING '!' "end" $@2
            8 $@3: ε •  [tSTRING]
           10 class: keyword_class • $@3 tSTRING '?' "end" $@4

            Conflict on tSTRING. shift/reduce($@1)
              tSTRING comes from state 1 goto by $@1

            Conflict on tSTRING. shift/reduce($@3)
              tSTRING comes from state 1 goto by $@3

            Conflict on tSTRING. reduce($@1)/reduce($@3)
              tSTRING comes from state 1 goto by $@1
              tSTRING comes from state 1 goto by $@3


            tSTRING  shift, and go to state 6

            tSTRING  reduce using rule 5 ($@1)
            tSTRING  reduce using rule 8 ($@3)

            $@1  go to state 7
            $@3  go to state 8


        State 2

            2 program: '+' • strings_1
           11 strings_1: • string_1
           14 string_1: • string
           16 string: • tSTRING

            tSTRING  shift, and go to state 9

            strings_1  go to state 10
            string_1   go to state 11
            string     go to state 12


        State 3

            3 program: '-' • strings_2
           12 strings_2: • string_1
           13          | • string_2
           14 string_1: • string
           15 string_2: • string '+'
           16 string: • tSTRING

            tSTRING  shift, and go to state 9

            strings_2  go to state 13
            string_1   go to state 14
            string_2   go to state 15
            string     go to state 16


        State 4

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 17


        State 5

            1 program: class •

            $default  reduce using rule 1 (program)


        State 6

            4 class: keyword_class tSTRING • "end"

            "end"  shift, and go to state 18


        State 7

            7 class: keyword_class $@1 • tSTRING '!' "end" $@2

            tSTRING  shift, and go to state 19


        State 8

           10 class: keyword_class $@3 • tSTRING '?' "end" $@4

            tSTRING  shift, and go to state 20


        State 9

           16 string: tSTRING •

            $default  reduce using rule 16 (string)


        State 10

            2 program: '+' strings_1 •

            $default  reduce using rule 2 (program)


        State 11

           11 strings_1: string_1 •

            $default  reduce using rule 11 (strings_1)


        State 12

           14 string_1: string •

            $default  reduce using rule 14 (string_1)


        State 13

            3 program: '-' strings_2 •

            $default  reduce using rule 3 (program)


        State 14

           12 strings_2: string_1 •

            $default  reduce using rule 12 (strings_2)


        State 15

           13 strings_2: string_2 •

            $default  reduce using rule 13 (strings_2)


        State 16

           14 string_1: string •  ["EOI"]
           15 string_2: string • '+'

            '+'  shift, and go to state 21

            $default  reduce using rule 14 (string_1)


        State 17

            0 $accept: program "EOI" •

            $default  accept


        State 18

            4 class: keyword_class tSTRING "end" •

            $default  reduce using rule 4 (class)


        State 19

            7 class: keyword_class $@1 tSTRING • '!' "end" $@2

            '!'  shift, and go to state 22


        State 20

           10 class: keyword_class $@3 tSTRING • '?' "end" $@4

            '?'  shift, and go to state 23


        State 21

           15 string_2: string '+' •

            $default  reduce using rule 15 (string_2)


        State 22

            7 class: keyword_class $@1 tSTRING '!' • "end" $@2

            "end"  shift, and go to state 24


        State 23

           10 class: keyword_class $@3 tSTRING '?' • "end" $@4

            "end"  shift, and go to state 25


        State 24

            6 $@2: ε •
            7 class: keyword_class $@1 tSTRING '!' "end" • $@2

            $default  reduce using rule 6 ($@2)

            $@2  go to state 26


        State 25

            9 $@4: ε •
           10 class: keyword_class $@3 tSTRING '?' "end" • $@4

            $default  reduce using rule 9 ($@4)

            $@4  go to state 27


        State 26

            7 class: keyword_class $@1 tSTRING '!' "end" $@2 •

            $default  reduce using rule 7 (class)


        State 27

           10 class: keyword_class $@3 tSTRING '?' "end" $@4 •

            $default  reduce using rule 10 (class)


      STR
    end

    it '#State#accessing_symbol' do
      path = "common/basic.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      expect(states.states.map(&:accessing_symbol)).to eq([
        states.find_symbol_by_s_value!("EOI"),
        states.find_symbol_by_s_value!("keyword_class"),
        states.find_symbol_by_s_value!("'+'"),
        states.find_symbol_by_s_value!("'-'"),
        states.find_symbol_by_s_value!("program"),
        states.find_symbol_by_s_value!("class"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("$@1"),
        states.find_symbol_by_s_value!("$@3"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("strings_1"),
        states.find_symbol_by_s_value!("string_1"),
        states.find_symbol_by_s_value!("string"),
        states.find_symbol_by_s_value!("strings_2"),
        states.find_symbol_by_s_value!("string_1"),
        states.find_symbol_by_s_value!("string_2"),
        states.find_symbol_by_s_value!("string"),
        states.find_symbol_by_s_value!("EOI"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("'+'"),
        states.find_symbol_by_s_value!("'!'"),
        states.find_symbol_by_s_value!("'?'"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("$@2"),
        states.find_symbol_by_s_value!("$@4"),
      ])
    end
  end

  describe '#reads_relation' do
    it do
      path = "states/reads_relation.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, itemsets: true, verbose: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0 conflicts: 1 shift/reduce
        State 7 conflicts: 1 shift/reduce


        State 0

            0 $accept: • program "end of file"
            1 program: • A
            2 A: • B C D A
            3  | • a
            4 B: ε •

            Conflict on a. shift/reduce(B)
              a comes from state 6 goto by D


            a  shift, and go to state 1

            a  reduce using rule 4 (B)

            program  go to state 2
            A        go to state 3
            B        go to state 4

          [Direct Read sets]
            read program  shift YYEOF

          [Reads Relation]
            (State 4, C)

          [Read sets]
            YYEOF
            a

          [Includes Relation]
            (State 0, A) -> (State 0, program)

          [Lookback Relation]
            (Rule: B -> ε) -> (State 0, B)

          [Follow sets]
            program -> YYEOF
            A -> YYEOF
            B -> a

          [Look-Ahead Sets]
            a  reduce using rule 4 (B)


        State 1

            3 A: a •

            $default  reduce using rule 3 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> a) -> (State 0, A)
            (Rule: A -> a) -> (State 7, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 3 (A)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 5

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 3

            1 program: A •

            $default  reduce using rule 1 (program)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: program -> A) -> (State 0, program)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 1 (program)


        State 4

            2 A: B • C D A
            5 C: ε •

            $default  reduce using rule 5 (C)

            C  go to state 6

          [Direct Read sets]

          [Reads Relation]
            (State 6, D)

          [Read sets]
            a

          [Includes Relation]

          [Lookback Relation]
            (Rule: C -> ε) -> (State 4, C)

          [Follow sets]
            C -> a

          [Look-Ahead Sets]
            a  reduce using rule 5 (C)


        State 5

            0 $accept: program "end of file" •

            $default  accept

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 6

            2 A: B C • D A
            6 D: ε •

            $default  reduce using rule 6 (D)

            D  go to state 7

          [Direct Read sets]
            read D  shift a

          [Reads Relation]
            (State 7, B)

          [Read sets]
            a

          [Includes Relation]

          [Lookback Relation]
            (Rule: D -> ε) -> (State 6, D)

          [Follow sets]
            D -> a

          [Look-Ahead Sets]
            a  reduce using rule 6 (D)


        State 7

            2 A: • B C D A
            2  | B C D • A
            3  | • a
            4 B: ε •

            Conflict on a. shift/reduce(B)
              a comes from state 6 goto by D


            a  shift, and go to state 1

            a  reduce using rule 4 (B)

            A  go to state 8
            B  go to state 4

          [Direct Read sets]

          [Reads Relation]
            (State 4, C)

          [Read sets]
            a

          [Includes Relation]
            (State 7, A) -> (State 0, A)
            (State 7, A) -> (State 7, A)

          [Lookback Relation]
            (Rule: B -> ε) -> (State 7, B)

          [Follow sets]
            A -> YYEOF
            B -> a

          [Look-Ahead Sets]
            a  reduce using rule 4 (B)


        State 8

            2 A: B C D A •

            $default  reduce using rule 2 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> B C D A) -> (State 0, A)
            (Rule: A -> B C D A) -> (State 7, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 2 (A)


      STR
    end
  end

  describe 'includes and lookback relations' do
    it 'preserves nullable suffix order, empty lookbacks, and shared reduction targets' do
      grammar = Lrama::Parser.new(<<~GRAMMAR, "relations.y").parse
        %%
        start: maybe required maybe;
        maybe: %empty | 'a';
        required: 'b';
      GRAMMAR
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      rule = grammar.rules[1]
      initial = states.states.first
      middle = initial.transition(rule.rhs[0])
      last = middle.transition(rule.rhs[1])
      target = last.transition(rule.rhs[2])
      includes = states.includes_relation.map do |key, gotos|
        [[key.from_state.id, key.next_sym.name], gotos.map { |goto| [goto.from_state.id, goto.next_sym.name] }]
      end

      expect(includes).to eq([
        [[last.id, "maybe"], [[initial.id, "start"]]],
        [[middle.id, "required"], [[initial.id, "start"]]],
      ])
      expect(states.lookback_relation[target.id][rule.id].map { |goto| [goto.from_state.id, goto.next_sym.name] }).to eq([[initial.id, "start"]])

      empty = grammar.rules.find { |entry| entry.lhs.name == "maybe" && entry.empty_rule? }
      [initial, last].each do |origin|
        expect(states.lookback_relation[origin.id][empty.id].map { |goto| [goto.from_state.id, goto.next_sym.name] }).to eq([[origin.id, "maybe"]])
      end
      reduction = grammar.rules.find { |entry| entry.lhs.name == "maybe" && !entry.empty_rule? }
      reduced = initial.transition(reduction.rhs.first)
      expect(states.lookback_relation[reduced.id][reduction.id].map(&:from_state).map(&:id)).to eq([initial.id, last.id])
    end

    it 'looks up each rule step once for a long nullable suffix' do
      names = 20.times.map { |index| "n#{index}" }
      source = "%%\nstart: #{names.join(' ')};\n" + names.map { |name| "#{name}: %empty | 'a';" }.join("\n")
      grammar = Lrama::Parser.new(source, "nullable.y").parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.send(:compute_lr0_states)
      lookups = 0
      states.states.each do |state|
        allow(state).to receive(:transitions_by_symbol_number).and_wrap_original do |method|
          lookups += 1
          method.call
        end
      end

      states.send(:compute_look_ahead_sets)

      expect(lookups).to eq(40)
      expect(states.includes_relation.size).to eq(20)
    end
  end

  describe '#includes_relation' do
    it do
      path = "states/includes_relation.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, itemsets: true, verbose: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "end of file"
            1 program: • A
            2 A: • b B
            3  | • a

            a  shift, and go to state 1
            b  shift, and go to state 2

            program  go to state 3
            A        go to state 4

          [Direct Read sets]
            read program  shift YYEOF

          [Reads Relation]

          [Read sets]
            YYEOF

          [Includes Relation]
            (State 0, A) -> (State 0, program)

          [Lookback Relation]

          [Follow sets]
            program -> YYEOF
            A -> YYEOF

          [Look-Ahead Sets]

        State 1

            3 A: a •

            $default  reduce using rule 3 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> a) -> (State 0, A)
            (Rule: A -> a) -> (State 8, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 3 (A)


        State 2

            2 A: b • B
            4 B: • c C

            c  shift, and go to state 5

            B  go to state 6

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 2, B) -> (State 0, A)
            (State 2, B) -> (State 8, A)

          [Lookback Relation]

          [Follow sets]
            B -> YYEOF

          [Look-Ahead Sets]

        State 3

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 7

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 4

            1 program: A •

            $default  reduce using rule 1 (program)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: program -> A) -> (State 0, program)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 1 (program)


        State 5

            4 B: c • C
            5 C: • d A

            d  shift, and go to state 8

            C  go to state 9

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 5, C) -> (State 2, B)

          [Lookback Relation]

          [Follow sets]
            C -> YYEOF

          [Look-Ahead Sets]

        State 6

            2 A: b B •

            $default  reduce using rule 2 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> b B) -> (State 0, A)
            (Rule: A -> b B) -> (State 8, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 2 (A)


        State 7

            0 $accept: program "end of file" •

            $default  accept

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 8

            2 A: • b B
            3  | • a
            5 C: d • A

            a  shift, and go to state 1
            b  shift, and go to state 2

            A  go to state 10

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 8, A) -> (State 5, C)

          [Lookback Relation]

          [Follow sets]
            A -> YYEOF

          [Look-Ahead Sets]

        State 9

            4 B: c C •

            $default  reduce using rule 4 (B)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: B -> c C) -> (State 2, B)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 4 (B)


        State 10

            5 C: d A •

            $default  reduce using rule 5 (C)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: C -> d A) -> (State 5, C)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 5 (C)


      STR
    end
  end

  describe '#compute_look_ahead_sets' do
    describe "state has 1 reduces and no transitions" do
      it "does not set look_ahead_sets" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER

          %%

          program: expr ;

          expr: tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_look_ahead_sets.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, lookaheads: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"

              tNUMBER  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              2 expr: tNUMBER •

              $default  reduce using rule 2 (expr)


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 4


          State 3

              1 program: expr •

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "EOI" •

              $default  accept


        STR
      end
    end

    describe "state has 1 reduces and no term transitions" do
      it "does not set look_ahead_sets" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER

          %%

          program: {} expr ;

          expr: tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_look_ahead_sets.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, lookaheads: true, itemsets: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"
              1 $@1: ε •
              2 program: • $@1 expr

              $default  reduce using rule 1 ($@1)

              $@1      go to state 1
              program  go to state 2


          State 1

              2 program: $@1 • expr
              3 expr: • tNUMBER

              tNUMBER  shift, and go to state 3

              expr  go to state 4


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 5


          State 3

              3 expr: tNUMBER •

              $default  reduce using rule 3 (expr)


          State 4

              2 program: $@1 expr •

              $default  reduce using rule 2 (program)


          State 5

              0 $accept: program "EOI" •

              $default  accept


        STR
      end
    end
  end

  describe '#compute_conflicts' do
    [:lalr, :ielr].each do |lr_type|
      [
        ["higher precedence", "%precedence 'b'\n%precedence HIGH", "%prec 'b'", "%prec HIGH", ["'c'"], 1],
        ["left associativity", "%left 'b'", "", "%prec 'b'", ["'c'"], 1],
        ["nonassociativity", "%nonassoc 'b'", "", "%prec 'b'", ["'c'"], 0],
        ["equal precedence", "%precedence 'b'", "%prec 'b'", "%prec 'b'", ["'b'", "'b'", "'c'"], 1],
      ].each do |description, precedences, empty_prec, direct_prec, unresolved, rr_count|
        it "reports only remaining #{lr_type} S/R conflicts after #{description}" do
          grammar = Lrama::Parser.new(<<~GRAMMAR, "resolved_shift.y").parse
            %define lr.type #{lr_type}
            #{precedences}
            %%
            start: 'a' empty 'b' 'x' | direct 'b' 'y' | 'a' 'b' 'z'
                 | 'a' empty 'c' | 'a' 'c' 'w';
            empty: %empty #{empty_prec};
            direct: 'a' #{direct_prec};
          GRAMMAR
          grammar.prepare
          states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          states.compute_ielr if lr_type == :ielr
          state = states.states.find { |s| s.reduces.length == 2 }

          expect(state.sr_conflicts.flat_map(&:symbols).map(&:name)).to eq(unresolved)
          expect(states.sr_conflicts_count).to eq(unresolved.length)
          expect(state.rr_conflicts.count).to eq(rr_count)
        end
      end

      [
        ["higher precedence", "%nonassoc 'b'\n%precedence HIGH",
         ["empty: %empty %prec HIGH;", "direct: 'a' %prec 'b';"], :reduce],
        ["nonassociativity before higher precedence", "%nonassoc 'b'\n%precedence HIGH",
         ["direct: 'a' %prec 'b';", "empty: %empty %prec HIGH;"], :error],
        ["left associativity", "%precedence LOW\n%left 'b'",
         ["empty: %empty %prec 'b';", "direct: 'a' %prec LOW;"], :reduce],
        ["nonassociativity", "%precedence LOW\n%nonassoc 'b'",
         ["empty: %empty %prec 'b';", "direct: 'a' %prec LOW;"], :error],
      ].each do |description, precedences, rules, resolution|
        it "stops comparing discarded shifts after #{description} in #{lr_type}" do
          grammar = Lrama::Parser.new(<<~GRAMMAR, "discarded_shift.y").parse
            %define lr.type #{lr_type}
            #{precedences}
            %%
            start: 'a' empty 'b' 'x' | direct 'b' 'y' | 'a' 'b' 'z';
            #{rules.join("\n")}
          GRAMMAR
          grammar.prepare
          states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          states.compute_ielr if lr_type == :ielr
          state = states.states.find { |s| s.reduces.length == 2 }
          token = grammar.find_symbol_by_s_value!("'b'")
          reduces = state.reduces.sort_by { |reduce| reduce.rule.id }

          expect(state.resolved_conflicts.map { |conflict| [conflict.reduce.rule.id, conflict.which] }).to eq([
            [reduces.first.rule.id, resolution],
          ])
          expect(state.term_transitions.find { |shift| shift.next_sym == token }.not_selected).to be(true)
          expect(reduces.first.selected_look_ahead.include?(token)).to be(resolution == :reduce)
          expect(reduces.last.selected_look_ahead).to include(token)
          expect(state.rr_conflicts.count).to eq(resolution == :error ? 0 : 1)
        end
      end

      [false, true].each do |shared_token|
        it "reports #{shared_token ? 'only the remaining' : 'no'} #{lr_type} R/R conflict after precedence resolution" do
          grammar = Lrama::Parser.new(<<~GRAMMAR, "selected_conflicts.y").parse
            %define lr.type #{lr_type}
            %precedence LOW
            %precedence 'b'
            %precedence HIGH
            %%
            start: 'a' empty 'b' 'x' | direct 'b' 'y' | 'a' 'b' 'z' | 'a' empty 'c'
                 #{"| direct 'c'" if shared_token};
            empty: %empty %prec LOW;
            direct: 'a' %prec HIGH;
          GRAMMAR
          grammar.prepare
          states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          states.compute_ielr if lr_type == :ielr
          state = states.states.find { |s| s.reduces.length == 2 }
          token = grammar.find_symbol_by_s_value!("'b'")

          expect(state.reduces.all? { |reduce| reduce.look_ahead.include?(token) }).to be(true)
          expect(state.rr_conflicts.flat_map(&:symbols).map(&:name)).to eq(shared_token ? ["'c'"] : [])
          expect(states.rr_conflicts_count).to eq(shared_token ? 1 : 0)
        end
      end
    end

    describe "rules have no explicit precedence" do
      it "inherits precedence from the last term in RHS" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER
          %token tUPLUS "unary+"
          %token tPLUS  "+"

          %left  tPLUS
          %right tUPLUS

          %%

          program: expr ;

          expr: tUPLUS expr
              | expr tPLUS expr
              | tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          Precedences

            precedence on "unary+" is used to resolve conflict on
              LALR
                state 5. Conflict between reduce by "expr -> tUPLUS expr" and shift "+" resolved as reduce ("+" < "unary+").

            precedence on "+" is used to resolve conflict on
              LALR
                state 5. Conflict between reduce by "expr -> tUPLUS expr" and shift "+" resolved as reduce ("+" < "unary+").
                state 8. Conflict between reduce by "expr -> expr tPLUS expr" and shift "+" resolved as reduce (%left "+").


          State 0

              0 $accept: • program "EOI"

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              program  go to state 3
              expr     go to state 4


          State 1

              4 expr: tNUMBER •

              $default  reduce using rule 4 (expr)


          State 2

              2 expr: "unary+" • expr

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              expr  go to state 5


          State 3

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 6


          State 4

              1 program: expr •
              3 expr: expr • "+" expr

              "+"  shift, and go to state 7

              $default  reduce using rule 1 (program)


          State 5

              2 expr: "unary+" expr •
              3     | expr • "+" expr

              $default  reduce using rule 2 (expr)

              Conflict between rule 2 and token "+" resolved as reduce ("+" < "unary+").


          State 6

              0 $accept: program "EOI" •

              $default  accept


          State 7

              3 expr: expr "+" • expr

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              expr  go to state 8


          State 8

              3 expr: expr • "+" expr
              3     | expr "+" expr •

              $default  reduce using rule 3 (expr)

              Conflict between rule 3 and token "+" resolved as reduce (%left "+").


        STR
      end
    end

    describe "conflict happens on %nonassoc operator" do
      it "resolved as 'run-time' error" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER
          %token tEQ "="

          %nonassoc tEQ

          %%

          program: expr ;

          expr: expr tEQ expr
              | tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          Precedences

            precedence on "=" is used to resolve conflict on
              LALR
                state 6. Conflict between reduce by "expr -> expr tEQ expr" and shift "=" resolved as an error (%nonassoc "=").


          State 0

              0 $accept: • program "EOI"

              tNUMBER  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              3 expr: tNUMBER •

              $default  reduce using rule 3 (expr)


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 4


          State 3

              1 program: expr •
              2 expr: expr • "=" expr

              "="  shift, and go to state 5

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "EOI" •

              $default  accept


          State 5

              2 expr: expr "=" • expr

              tNUMBER  shift, and go to state 1

              expr  go to state 6


          State 6

              2 expr: expr • "=" expr
              2     | expr "=" expr •

              "="  error (nonassociative)

              $default  reduce using rule 2 (expr)

              Conflict between rule 2 and token "=" resolved as an error (%nonassoc "=").


        STR
      end
    end

    describe "conflict happens on %precedence operator" do
      it "resolved as 'run-time' error so that conflict is kept" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token NUM

          %precedence '+'
          %precedence '*'

          %%

          program: expr ;

          expr: expr '+' expr
              | expr '*' expr
              | NUM
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 7 conflicts: 1 shift/reduce
          State 8 conflicts: 1 shift/reduce


          Precedences

            precedence on '+' is used to resolve conflict on
              LALR
                state 7. Conflict between reduce by "expr -> expr '+' expr" and shift '*' resolved as shift ('+' < '*').
                state 8. Conflict between reduce by "expr -> expr '*' expr" and shift '+' resolved as reduce ('+' < '*').

            precedence on '*' is used to resolve conflict on
              LALR
                state 7. Conflict between reduce by "expr -> expr '+' expr" and shift '*' resolved as shift ('+' < '*').
                state 8. Conflict between reduce by "expr -> expr '*' expr" and shift '+' resolved as reduce ('+' < '*').


          State 0

              0 $accept: • program "end of file"

              NUM  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              4 expr: NUM •

              $default  reduce using rule 4 (expr)


          State 2

              0 $accept: program • "end of file"

              "end of file"  shift, and go to state 4


          State 3

              1 program: expr •
              2 expr: expr • '+' expr
              3     | expr • '*' expr

              '+'  shift, and go to state 5
              '*'  shift, and go to state 6

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "end of file" •

              $default  accept


          State 5

              2 expr: expr '+' • expr

              NUM  shift, and go to state 1

              expr  go to state 7


          State 6

              3 expr: expr '*' • expr

              NUM  shift, and go to state 1

              expr  go to state 8


          State 7

              2 expr: expr • '+' expr
              2     | expr '+' expr •
              3     | expr • '*' expr

              Conflict on '+'. shift/reduce(expr)
                '+' comes from state 0 goto by expr
                '+' comes from state 5 goto by expr
                '+' comes from state 6 goto by expr


              '+'  shift, and go to state 5
              '*'  shift, and go to state 6

              "end of file"  reduce using rule 2 (expr)
              '+'            reduce using rule 2 (expr)
              '*'            reduce using rule 2 (expr)

              Conflict between rule 2 and token '*' resolved as shift ('+' < '*').


          State 8

              2 expr: expr • '+' expr
              3     | expr • '*' expr
              3     | expr '*' expr •

              Conflict on '*'. shift/reduce(expr)
                '*' comes from state 0 goto by expr
                '*' comes from state 5 goto by expr
                '*' comes from state 6 goto by expr


              '*'  shift, and go to state 6

              "end of file"  reduce using rule 3 (expr)
              '+'            reduce using rule 3 (expr)
              '*'            reduce using rule 3 (expr)

              Conflict between rule 3 and token '+' resolved as reduce ('+' < '*').


        STR
      end
    end
  end

  describe '#compute_default_reduction' do
    it "selects a rule having most lookahead as default reduction rule" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %union {
            int i;
        }

        %token EOI 0 "EOI"
        %token <l> tNUMBER
        %token <str> tID
        %token tPLUS  "+"
        %token tMINUS "-"
        %token do
        %token end
        %token tCOLON2 "::"

        %%

        program: stmt ;

        stmt: expr
            ;

        expr: primary do end
            | receiver '.' ident
            | receiver tCOLON2 ident
            ;

        receiver: ident ;

        primary: ident ;

        ident: tID ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/compute_default_reduction.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "EOI"

            tID  shift, and go to state 1

            program   go to state 2
            stmt      go to state 3
            expr      go to state 4
            receiver  go to state 5
            primary   go to state 6
            ident     go to state 7


        State 1

            8 ident: tID •

            $default  reduce using rule 8 (ident)


        State 2

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 8


        State 3

            1 program: stmt •

            $default  reduce using rule 1 (program)


        State 4

            2 stmt: expr •

            $default  reduce using rule 2 (stmt)


        State 5

            4 expr: receiver • '.' ident
            5     | receiver • "::" ident

            "::"  shift, and go to state 9
            '.'   shift, and go to state 10


        State 6

            3 expr: primary • do end

            do  shift, and go to state 11


        State 7

            6 receiver: ident •
            7 primary: ident •

            do        reduce using rule 7 (primary)
            $default  reduce using rule 6 (receiver)


        State 8

            0 $accept: program "EOI" •

            $default  accept


        State 9

            5 expr: receiver "::" • ident

            tID  shift, and go to state 1

            ident  go to state 12


        State 10

            4 expr: receiver '.' • ident

            tID  shift, and go to state 1

            ident  go to state 13


        State 11

            3 expr: primary do • end

            end  shift, and go to state 14


        State 12

            5 expr: receiver "::" ident •

            $default  reduce using rule 5 (expr)


        State 13

            4 expr: receiver '.' ident •

            $default  reduce using rule 4 (expr)


        State 14

            3 expr: primary do end •

            $default  reduce using rule 3 (expr)


      STR
    end

    it "does not have default_reduction_rule if error token can be shifted" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %union {
            int i;
        }

        %token EOI 0 "EOI"
        %token <l> tNUMBER
        %token <str> tID
        %token tPLUS  "+"
        %token tMINUS "-"
        %token do
        %token end
        %token tCOLON2 "::"

        %%

        program: stmt ;

        stmt: expr
            ;

        expr: primary do end
            | receiver '.' ident
            | receiver tCOLON2 ident
            ;

        receiver: ident
                | ident error
                ;

        primary: ident ;

        ident: tID ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/compute_default_reduction.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "EOI"

            tID  shift, and go to state 1

            program   go to state 2
            stmt      go to state 3
            expr      go to state 4
            receiver  go to state 5
            primary   go to state 6
            ident     go to state 7


        State 1

            9 ident: tID •

            $default  reduce using rule 9 (ident)


        State 2

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 8


        State 3

            1 program: stmt •

            $default  reduce using rule 1 (program)


        State 4

            2 stmt: expr •

            $default  reduce using rule 2 (stmt)


        State 5

            4 expr: receiver • '.' ident
            5     | receiver • "::" ident

            "::"  shift, and go to state 9
            '.'   shift, and go to state 10


        State 6

            3 expr: primary • do end

            do  shift, and go to state 11


        State 7

            6 receiver: ident •
            7         | ident • error
            8 primary: ident •

            error  shift, and go to state 12

            do    reduce using rule 8 (primary)
            "::"  reduce using rule 6 (receiver)
            '.'   reduce using rule 6 (receiver)


        State 8

            0 $accept: program "EOI" •

            $default  accept


        State 9

            5 expr: receiver "::" • ident

            tID  shift, and go to state 1

            ident  go to state 13


        State 10

            4 expr: receiver '.' • ident

            tID  shift, and go to state 1

            ident  go to state 14


        State 11

            3 expr: primary do • end

            end  shift, and go to state 15


        State 12

            7 receiver: ident error •

            $default  reduce using rule 7 (receiver)


        State 13

            5 expr: receiver "::" ident •

            $default  reduce using rule 5 (expr)


        State 14

            4 expr: receiver '.' ident •

            $default  reduce using rule 4 (expr)


        State 15

            3 expr: primary do end •

            $default  reduce using rule 3 (expr)


      STR
    end
  end

  describe '#compute_inadequacy_annotations' do
    let(:grammar) do
      grammar = Lrama::Parser.new("%%\nstart: 'a';\n", "annotations.y").parse
      grammar.prepare
      grammar
    end
    let(:states) { described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new)) }
    let(:token) { grammar.terms.last }
    let(:source) { Lrama::State.new(0, token, []) }
    let(:updater) { Lrama::State.new(1, token, []) }
    let(:first_predecessor) { Lrama::State.new(2, token, []) }
    let(:second_predecessor) { Lrama::State.new(3, token, []) }
    let(:action) { Lrama::State::Action::Reduce.new(Lrama::State::Item.new(rule: grammar.rules.last, position: 1)) }
    let(:unchanged) { Lrama::State::InadequacyAnnotation.new(source, token, [action], { action => 0b01 }) }
    let(:changed) { Lrama::State::InadequacyAnnotation.new(updater, token, [action], { action => 0b01 }) }

    before do
      states.states.concat([source, updater, first_predecessor, second_predecessor])
      states.states.each do |state|
        allow(state).to receive(:annotate_manifestation)
        allow(state).to receive(:predecessors).and_return([])
      end
      source.annotation_list.concat([unchanged, changed])
    end

    [0b11, nil].each do |contributions|
      it "repropagates merged and new annotations to every predecessor when contributions become #{contributions.inspect}" do
        added = Lrama::State::InadequacyAnnotation.new(first_predecessor, token, [action], { action => 0b10 })
        updater.annotation_list << Lrama::State::InadequacyAnnotation.new(updater, token, [action], { action => 0b10 })
        allow(source).to receive(:predecessors).and_return([first_predecessor, second_predecessor])
        allow(updater).to receive(:predecessors).and_return([source])
        allow(updater).to receive(:annotate_predecessor) do
          changed.merge_matrix([{ action => contributions }])
          source.annotation_list << added
          true
        end
        propagated = []
        allow(source).to receive(:annotate_predecessor) do |predecessor, annotations = source.annotation_list|
          propagated << [predecessor.id, annotations.map {|annotation| annotation.state.id }]
          false
        end

        states.send(:compute_inadequacy_annotations)

        expect(propagated).to eq([
          [first_predecessor.id, [source.id, updater.id]],
          [second_predecessor.id, [source.id, updater.id]],
          [first_predecessor.id, [updater.id, first_predecessor.id]],
          [second_predecessor.id, [updater.id, first_predecessor.id]],
        ])
      end
    end

    it "keeps changes made during self-loop propagation pending" do
      allow(source).to receive(:predecessors).and_return([source])
      propagated = []
      allow(source).to receive(:annotate_predecessor) do |_, annotations = source.annotation_list|
        propagated << annotations.map {|annotation| annotation.state.id }
        raise "Annotation propagation did not converge" if propagated.length > 2
        changed.merge_matrix([{ action => 0b11 }])
      end

      states.send(:compute_inadequacy_annotations)

      expect(propagated).to eq([[source.id, updater.id], [updater.id]])
    end
  end

  describe '#merge_lookaheads' do
    let(:grammar) do
      grammar = Lrama::Parser.new("%%\nstart: 'a' 'b' | 'a' 'c' | 'a' 'd';\n", "merge.y").parse
      grammar.prepare
      grammar
    end
    let(:states) do
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states
    end
    let(:state) { states.states.first.term_transitions.first.to_state }
    let(:token) { state.kernels.first.rule.rhs.last }
    let(:another_token) { state.kernels.last.rule.rhs.last }
    let(:token_bitmap) { Lrama::Bitmap.from_integer(token.number) }
    let(:incoming_bitmap) { token_bitmap | Lrama::Bitmap.from_integer(another_token.number) }
    let(:incoming) { state.kernels.map {|item| [item, incoming_bitmap] }.to_h }

    before do
      state.lookaheads_recomputed = true
      state.item_lookahead_set = state.kernels.map {|item| [item, token_bitmap] }.to_h
    end

    it "merges incoming lookaheads without mutating either input" do
      original = state.item_lookahead_set
      allow(state).to receive(:transitions).and_return([])

      states.send(:merge_lookaheads, state, incoming)

      expect(state.item_lookahead_set.values).to all(eq(incoming_bitmap))
      expect(original.values).to all(eq(token_bitmap))
      expect(incoming.values).to all(eq(incoming_bitmap))
    end

    it "repropagates to processed successors and stops at the first unprocessed successor" do
      first, second, third = state.transitions.map(&:to_state)
      first.lookaheads_recomputed = true
      second.lookaheads_recomputed = false
      third.lookaheads_recomputed = true
      visited = []
      allow(states).to receive(:compute_state) {|_, _, successor| visited << successor.id }

      states.send(:merge_lookaheads, state, incoming)

      expect(visited).to eq([first.id])
      expect(second.lookaheads_recomputed).to be(false)
    end

    it "does not revisit successors when there are no new lookaheads" do
      original = state.item_lookahead_set
      visited = []
      allow(states).to receive(:compute_state) {|_, _, successor| visited << successor.id }

      states.send(:merge_lookaheads, state, original.dup)

      expect(state.item_lookahead_set).to equal(original)
      expect(visited).to eq([])
    end

    it "stores new lookaheads before propagating through a self-loop" do
      transition = Lrama::State::Action::Shift.new(state, token, [], state)
      allow(state).to receive(:transitions).and_return([transition])
      calls = 0
      allow(states).to receive(:compute_state) do |_, _, successor|
        calls += 1
        raise "Lookahead propagation did not converge" if calls > 2
        states.send(:merge_lookaheads, successor, incoming)
      end

      states.send(:merge_lookaheads, state, incoming)

      expect(calls).to eq(1)
    end
  end

  describe '#compute_state' do
    it "computes incoming contributions once while choosing an existing isocore" do
      grammar = Lrama::Parser.new("%%\nstart: left 'c' | right 'd';\nleft: 'a';\nright: 'a';\n", "state.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      predecessor = states.states.first
      transition = predecessor.term_transitions.first
      successor = transition.to_state
      first, second = successor.kernels
      token = grammar.rules.first.rhs.last
      actions = successor.reduces
      annotation = Lrama::State::InadequacyAnnotation.new(successor, token, actions, {
        actions[0] => 0b01, actions[1] => 0b10,
      })
      successor.annotation_list << annotation
      token_bitmap = Lrama::Bitmap.from_integer(token.number)
      successor.item_lookahead_set = { first => token_bitmap, second => 0 }
      successor.lookaheads_recomputed = true
      split = Lrama::State.new(states.states.length, successor.accessing_symbol, successor.kernels)
      split.lalr_isocore = successor
      split.item_lookahead_set = { first => 0, second => token_bitmap | Lrama::Bitmap.from_integer(grammar.rules.last.rhs.first.number) }
      split.lookaheads_recomputed = true
      successor.ielr_isocores << split
      split.ielr_isocores = successor.ielr_isocores
      incoming = { first => 0, second => token_bitmap }
      allow(predecessor).to receive(:propagate_lookaheads).with(successor).and_return(incoming)
      expect(annotation).to receive(:dominant_contribution).with(successor.item_lookahead_set, successor.kernels).once.and_call_original
      expect(annotation).to receive(:dominant_contribution).with(split.item_lookahead_set, successor.kernels).once.and_call_original
      expect(annotation).to receive(:dominant_contribution).with(incoming, successor.kernels).once.and_call_original

      states.send(:compute_state, predecessor, transition, successor)

      expect(predecessor.items_to_state[transition.to_items]).to equal(split)
    end

    it "initializes empty filtered lookaheads once for a state without annotations" do
      grammar = Lrama::Parser.new("%%\nstart: 'a' 'b';\n", "state.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      predecessor = states.states.find { |state| state.accessing_symbol == grammar.rules.last.rhs.first }
      transition = predecessor.transitions.first
      successor = transition.to_state
      successor.item_lookahead_set = { successor.kernels.first => Lrama::Bitmap.from_integer(grammar.rules.last.rhs.last.number) }
      expect(predecessor).not_to receive(:propagate_lookaheads)
      expect(predecessor).not_to receive(:update_transition)

      states.send(:compute_state, predecessor, transition, successor)
      lookaheads = successor.item_lookahead_set
      states.send(:compute_state, predecessor, transition, successor)

      expect(successor.lookaheads_recomputed).to be(true)
      expect(lookaheads).to eq({ successor.kernels.first => 0 }.compare_by_identity)
      expect(successor.item_lookahead_set).to equal(lookaheads)
      expect(successor.ielr_isocores).to eq([successor])
    end
  end

  describe '#clear_look_ahead_sets' do
    it "clears reduction lookaheads and their sources before recomputing them" do
      grammar = Lrama::Parser.new("%%\nstart: left 'a' | left 'b' | right 'a';\nleft: 'x';\nright: 'x';\n", "lookaheads.y").parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_la_sources_for_conflicted_states
      reductions = states.states.flat_map(&:reduces)
      original = reductions.map(&:look_ahead).compact
      expect(original).not_to be_empty
      expect(reductions.map(&:look_ahead_sources).compact).not_to be_empty

      states.send(:clear_look_ahead_sets)

      expect(reductions.map(&:look_ahead)).to all(eq([]))
      expect(reductions.map(&:look_ahead_sources)).to all(eq({}))
      expect(original.flatten).not_to be_empty
    end
  end

  describe '#compute_ielr' do
    {
      'nullable rules' => "%%\nstart: value;\nvalue: 'n' | %empty;\n",
      'resolved and unresolved conflicts' => <<~GRAMMAR,
        %left '+'
        %nonassoc '<'
        %%
        expr: expr '+' expr | expr '<' expr | expr '?' expr | 'n';
      GRAMMAR
    }.each do |description, source|
      it "reuses lookahead sets without changing transitions or tables for #{description} when no states split" do
        grammar = Lrama::Parser.new(source, "unchanged.y").parse
        grammar.prepare
        states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        original_states = states.states.map(&:object_id)
        transitions = states.states.flat_map(&:transitions).map { |transition| [transition.object_id, transition.to_state.object_id] }
        lookaheads = states.la
        conflicts = states.states.map { |state| [state.sr_conflicts.count, state.rr_conflicts.count, state.resolved_conflicts.map(&:report_message)] }
        table_names = [:yypact, :yydefact, :yytable, :yycheck, :yypgoto, :yydefgoto]
        context = Lrama::Context.new(states)
        tables = table_names.map { |name| context.public_send(name) }
        recomputed = []
        [:clear_look_ahead_sets, :compute_look_ahead_sets].each do |name|
          allow(states).to receive(name).and_wrap_original do |method|
            recomputed << name
            method.call
          end
        end

        states.compute_ielr

        expect(recomputed).to be_empty
        expect(states.states.map(&:object_id)).to eq(original_states)
        expect(states.states.flat_map(&:transitions).map { |transition| [transition.object_id, transition.to_state.object_id] }).to eq(transitions)
        expect(states.la).to equal(lookaheads)
        expect(states.states.map { |state| [state.sr_conflicts.count, state.rr_conflicts.count, state.resolved_conflicts.map(&:report_message)] }).to eq(conflicts)
        context = Lrama::Context.new(states)
        expect(table_names.map { |name| context.public_send(name) }).to eq(tables)
      end
    end

    it 'rebuilds lookahead sets when state splitting changes transitions' do
      path = "integration/ielr.y"
      grammar = Lrama::Parser.new(File.read(fixture_path(path)), path).parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      original_count = states.states_count
      expect(states).to receive(:clear_look_ahead_sets).once.ordered.and_call_original
      expect(states).to receive(:compute_look_ahead_sets).once.ordered.and_call_original

      states.compute_ielr

      expect(states.states_count).to be > original_count
      split_states = states.states.drop(original_count)
      expect(split_states.flat_map(&:reduces).map(&:look_ahead)).to include(be_an(Array))
      expect { Lrama::Context.new(states) }.not_to raise_error
    end

    it 'stores a boolean for each follow kernel item' do
      path = "integration/ielr.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      values = states.states.flat_map do |state|
        state.follow_kernel_items.values.compact.flat_map(&:values)
      end

      expect(values).to include(false)
      expect(values).to all(satisfy("be a boolean") { |value| value == true || value == false })
    end

    it 'recompute states' do
      path = "integration/ielr.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Precedences

          precedence on a is used to resolve conflict on
            LALR
              state 14. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

            IELR
              state 14. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

          precedence on tHIGHEST is used to resolve conflict on
            LALR
              state 14. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

            IELR
              state 14. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).


        Split States

            State 19 is split from state 4
            State 20 is split from state 9
            State 21 is split from state 14

        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S  go to state 3


        State 1

            1 S: a • A B a

            a  shift, and go to state 4

            A  go to state 5


        State 2

            2 S: b • A B b

            a  shift, and go to state 19

            A  go to state 6


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 7


        State 4

            3 A: a • C D E

            a  shift, and go to state 8

            C  go to state 9
            D  go to state 10


        State 5

            1 S: a A • B a

            c  shift, and go to state 11

            $default  reduce using rule 5 (B)

            B  go to state 12


        State 6

            2 S: b A • B b

            c  shift, and go to state 11

            $default  reduce using rule 5 (B)

            B  go to state 13


        State 7

            0 $accept: S "end of file" •

            $default  accept


        State 8

            7 D: a •

            $default  reduce using rule 7 (D)


        State 9

            3 A: a C • D E

            a  shift, and go to state 8

            D  go to state 14


        State 10

            6 C: D •

            $default  reduce using rule 6 (C)


        State 11

            4 B: c •

            $default  reduce using rule 4 (B)


        State 12

            1 S: a A B • a

            a  shift, and go to state 15


        State 13

            2 S: b A B • b

            b  shift, and go to state 16


        State 14

            3 A: a C D • E

            $default  reduce using rule 9 (E)

            E  go to state 18


        State 15

            1 S: a A B a •

            $default  reduce using rule 1 (S)


        State 16

            2 S: b A B b •

            $default  reduce using rule 2 (S)


        State 17

            8 E: a •

            $default  reduce using rule 8 (E)


        State 18

            3 A: a C D E •

            $default  reduce using rule 3 (A)


        State 19

            3 A: a • C D E

            a  shift, and go to state 8

            C  go to state 20
            D  go to state 10


        State 20

            3 A: a C • D E

            a  shift, and go to state 8

            D  go to state 21


        State 21

            3 A: a C D • E

            a  shift, and go to state 17

            $default  reduce using rule 9 (E)

            E  go to state 18


      STR
    end

    it 'recompute states' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token <val> NUM
        %token tEQ "=="
        %type <val> expr

        %nonassoc tEQ

        %%

        program : /* empty */
             | expr { printf("=> %d", $1); }
             ;

        expr : NUM
             | expr tEQ expr { $$ = $1; }
             ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ielr_nonassoc.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Precedences

          precedence on "==" is used to resolve conflict on
            LALR
              state 6. Conflict between reduce by "expr -> expr tEQ expr" and shift "==" resolved as an error (%nonassoc "==").

            IELR
              state 6. Conflict between reduce by "expr -> expr tEQ expr" and shift "==" resolved as an error (%nonassoc "==").


        State 0

            0 $accept: • program "end of file"

            NUM  shift, and go to state 1

            $default  reduce using rule 1 (program)

            program  go to state 2
            expr     go to state 3


        State 1

            3 expr: NUM •

            $default  reduce using rule 3 (expr)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 4


        State 3

            2 program: expr •
            4 expr: expr • "==" expr

            "=="  shift, and go to state 5

            $default  reduce using rule 2 (program)


        State 4

            0 $accept: program "end of file" •

            $default  accept


        State 5

            4 expr: expr "==" • expr

            NUM  shift, and go to state 1

            expr  go to state 6


        State 6

            4 expr: expr • "==" expr
            4     | expr "==" expr •

            "=="  error (nonassociative)

            $default  reduce using rule 4 (expr)


      STR
    end

    it 'recompute states' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token NUM

        %nonassoc  tCMP
        %left '>'
        %left '+'

        %%

        program : arg
                ;

        arg : arg '+' arg
            | rel_expr    %prec tCMP
            | NUM
            ;

        relop : '>'
              ;

        rel_expr : arg relop arg   %prec '>'
                 ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ielr_prec.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Precedences

          precedence on '>' is used to resolve conflict on
            LALR
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '>' resolved as reduce ('>' < '+').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '>' resolved as reduce (%left '>').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '+' resolved as shift ('>' < '+').

            IELR
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '>' resolved as reduce ('>' < '+').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '>' resolved as reduce (%left '>').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '+' resolved as shift ('>' < '+').

          precedence on '+' is used to resolve conflict on
            LALR
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '>' resolved as reduce ('>' < '+').
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '+' resolved as reduce (%left '+').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '+' resolved as shift ('>' < '+').

            IELR
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '>' resolved as reduce ('>' < '+').
              state 9. Conflict between reduce by "arg -> arg '+' arg" and shift '+' resolved as reduce (%left '+').
              state 10. Conflict between reduce by "rel_expr -> arg relop arg" and shift '+' resolved as shift ('>' < '+').


        State 0

            0 $accept: • program "end of file"

            NUM  shift, and go to state 1

            program   go to state 2
            arg       go to state 3
            rel_expr  go to state 4


        State 1

            4 arg: NUM •

            $default  reduce using rule 4 (arg)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 5


        State 3

            1 program: arg •
            2 arg: arg • '+' arg
            6 rel_expr: arg • relop arg

            '>'  shift, and go to state 6
            '+'  shift, and go to state 7

            $default  reduce using rule 1 (program)

            relop  go to state 8


        State 4

            3 arg: rel_expr •

            $default  reduce using rule 3 (arg)


        State 5

            0 $accept: program "end of file" •

            $default  accept


        State 6

            5 relop: '>' •

            $default  reduce using rule 5 (relop)


        State 7

            2 arg: arg '+' • arg

            NUM  shift, and go to state 1

            arg       go to state 9
            rel_expr  go to state 4


        State 8

            6 rel_expr: arg relop • arg

            NUM  shift, and go to state 1

            arg       go to state 10
            rel_expr  go to state 4


        State 9

            2 arg: arg • '+' arg
            2    | arg '+' arg •
            6 rel_expr: arg • relop arg

            $default  reduce using rule 2 (arg)

            relop  go to state 8


        State 10

            2 arg: arg • '+' arg
            6 rel_expr: arg • relop arg
            6         | arg relop arg •

            '+'  shift, and go to state 7

            $default  reduce using rule 6 (rel_expr)

            relop  go to state 8


      STR
    end

    it 'recompute states' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token a
        %token b
        %token c

        %precedence tLOWEST
        %precedence a
        %precedence tHIGHEST

        %%

        S: S2
         ;

        S2: a A B a
          | b A B b
          ;

        A: a C D E
         ;

        B: c
         | // empty
         ;

        C: D
         ;

        D: a
         ;

        E: a
         | %prec tHIGHEST // empty
         ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ArgumentError_on_goto_follows.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      expect { states.compute_ielr }.not_to raise_error

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Precedences

          precedence on a is used to resolve conflict on
            LALR
              state 15. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

            IELR
              state 15. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

          precedence on tHIGHEST is used to resolve conflict on
            LALR
              state 15. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).

            IELR
              state 15. Conflict between reduce by "E -> ε" and shift a resolved as reduce (a < tHIGHEST).


        Split States

            State 20 is split from state 5
            State 21 is split from state 10
            State 22 is split from state 15

        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S   go to state 3
            S2  go to state 4


        State 1

            2 S2: a • A B a

            a  shift, and go to state 5

            A  go to state 6


        State 2

            3 S2: b • A B b

            a  shift, and go to state 20

            A  go to state 7


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 8


        State 4

            1 S: S2 •

            $default  reduce using rule 1 (S)


        State 5

            4 A: a • C D E

            a  shift, and go to state 9

            C  go to state 10
            D  go to state 11


        State 6

            2 S2: a A • B a

            c  shift, and go to state 12

            $default  reduce using rule 6 (B)

            B  go to state 13


        State 7

            3 S2: b A • B b

            c  shift, and go to state 12

            $default  reduce using rule 6 (B)

            B  go to state 14


        State 8

            0 $accept: S "end of file" •

            $default  accept


        State 9

            8 D: a •

            $default  reduce using rule 8 (D)


        State 10

            4 A: a C • D E

            a  shift, and go to state 9

            D  go to state 15


        State 11

            7 C: D •

            $default  reduce using rule 7 (C)


        State 12

            5 B: c •

            $default  reduce using rule 5 (B)


        State 13

            2 S2: a A B • a

            a  shift, and go to state 16


        State 14

            3 S2: b A B • b

            b  shift, and go to state 17


        State 15

            4 A: a C D • E

            $default  reduce using rule 10 (E)

            E  go to state 19


        State 16

            2 S2: a A B a •

            $default  reduce using rule 2 (S2)


        State 17

            3 S2: b A B b •

            $default  reduce using rule 3 (S2)


        State 18

            9 E: a •

            $default  reduce using rule 9 (E)


        State 19

            4 A: a C D E •

            $default  reduce using rule 4 (A)


        State 20

            4 A: a • C D E

            a  shift, and go to state 9

            C  go to state 21
            D  go to state 11


        State 21

            4 A: a C • D E

            a  shift, and go to state 9

            D  go to state 22


        State 22

            4 A: a C D • E

            a  shift, and go to state 18

            $default  reduce using rule 10 (E)

            E  go to state 19


      STR
    end

    it 'recompute states' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token a
        %token b

        %left a
        %left b

        %%

        S: S2
         ;

        S2: a A a
          | b A b
          ;

        A: a
         | a a
         | a b
         ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ielr.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Precedences

          precedence on a is used to resolve conflict on
            LALR
              state 5. Conflict between reduce by "A -> a" and shift a resolved as reduce (%left a).
              state 5. Conflict between reduce by "A -> a" and shift b resolved as shift (a < b).

            IELR
              state 5. Conflict between reduce by "A -> a" and shift a resolved as reduce (%left a).
              state 13. Conflict between reduce by "A -> a" and shift b resolved as shift (a < b).

          precedence on b is used to resolve conflict on
            LALR
              state 5. Conflict between reduce by "A -> a" and shift b resolved as shift (a < b).

            IELR
              state 13. Conflict between reduce by "A -> a" and shift b resolved as shift (a < b).


        Split States

            State 13 is split from state 5

        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S   go to state 3
            S2  go to state 4


        State 1

            2 S2: a • A a

            a  shift, and go to state 5

            A  go to state 6


        State 2

            3 S2: b • A b

            a  shift, and go to state 13

            A  go to state 7


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 8


        State 4

            1 S: S2 •

            $default  reduce using rule 1 (S)


        State 5

            4 A: a •
            5  | a • a
            6  | a • b

            b  shift, and go to state 10

            $default  reduce using rule 4 (A)


        State 6

            2 S2: a A • a

            a  shift, and go to state 11


        State 7

            3 S2: b A • b

            b  shift, and go to state 12


        State 8

            0 $accept: S "end of file" •

            $default  accept


        State 9

            5 A: a a •

            $default  reduce using rule 5 (A)


        State 10

            6 A: a b •

            $default  reduce using rule 6 (A)


        State 11

            2 S2: a A a •

            $default  reduce using rule 2 (S2)


        State 12

            3 S2: b A b •

            $default  reduce using rule 3 (S2)


        State 13

            4 A: a •
            5  | a • a
            6  | a • b

            a  shift, and go to state 9
            b  shift, and go to state 10

            $default  reduce using rule 4 (A)


      STR
    end

    it 'recompute states for R/R conflicts' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token a
        %token b
        %token c

        %%

        S: S2
         ;

        S2: a A1 a
          | a A2 b
          | b A1 b
          | b A2 a
          ;

        A1: c
         ;

        A2: c
         ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ArgumentError_on_goto_follows.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      expect { states.compute_ielr }.not_to raise_error

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Split States

            State 15 is split from state 5

        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S   go to state 3
            S2  go to state 4


        State 1

            2 S2: a • A1 a
            3   | a • A2 b

            c  shift, and go to state 5

            A1  go to state 6
            A2  go to state 7


        State 2

            4 S2: b • A1 b
            5   | b • A2 a

            c  shift, and go to state 15

            A1  go to state 8
            A2  go to state 9


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 10


        State 4

            1 S: S2 •

            $default  reduce using rule 1 (S)


        State 5

            6 A1: c •
            7 A2: c •

            b         reduce using rule 7 (A2)
            $default  reduce using rule 6 (A1)


        State 6

            2 S2: a A1 • a

            a  shift, and go to state 11


        State 7

            3 S2: a A2 • b

            b  shift, and go to state 12


        State 8

            4 S2: b A1 • b

            b  shift, and go to state 13


        State 9

            5 S2: b A2 • a

            a  shift, and go to state 14


        State 10

            0 $accept: S "end of file" •

            $default  accept


        State 11

            2 S2: a A1 a •

            $default  reduce using rule 2 (S2)


        State 12

            3 S2: a A2 b •

            $default  reduce using rule 3 (S2)


        State 13

            4 S2: b A1 b •

            $default  reduce using rule 4 (S2)


        State 14

            5 S2: b A2 a •

            $default  reduce using rule 5 (S2)


        State 15

            6 A1: c •
            7 A2: c •

            a         reduce using rule 7 (A2)
            $default  reduce using rule 6 (A1)


      STR
    end
  end

  describe "#validate!" do
    let(:y) do
      <<~'STR'
        %union {
            int i;
            long l;
            char *str;
        }

        %token EOI 0 "EOI"
        %token <i> '\\'  "backslash"
        %token <i> '\13' "escaped vertical tab"
        %token <i> keyword_class
        %token <i> keyword_class2
        %token <l> tNUMBER
        %token <str> tSTRING
        %token <i> keyword_end "end"
        %token tPLUS  "+"
        %token tMINUS "-"
        %token tEQ    "="
        %token tEQEQ  "=="

        %type <i> class /* comment for class */

        %nonassoc tEQEQ
        %left  tPLUS tMINUS '>'
        %right tEQ

        %%

        program: class
               | '+' strings_1
               | '-' strings_2
               ;

        class : keyword_class tSTRING keyword_end %prec tPLUS
                  { code 1 }
              | keyword_class { code 2 } tSTRING '!' keyword_end { code 3 } %prec "="
              | keyword_class { code 4 } tSTRING '?' keyword_end { code 5 } %prec '>'
              ;

        strings_1: string_1
                 ;

        strings_2: string_1
                 | string_2
                 ;

        string_1: string
                ;

          string_2: string '+'
                  ;

          string: tSTRING
                ;

          %%
      STR
    end

    context "when %expect is specified" do
      context "when the number of s/r conflicts is same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 2
          STR
        end

        it "has errors for r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect{ states.validate!(logger) }.to raise_error(SystemExit)
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end

      context "when the number of s/r conflicts is not same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 0
          STR
        end

        it "has errors for s/r conflicts and r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect{ states.validate!(logger) }.to raise_error(SystemExit)
          expect(logger).to have_received(:error).with("shift/reduce conflicts: 2 found, 0 expected")
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end
    end

    describe "%expect is not specified" do
      let(:header) do
        <<~STR
          %{
          // Prologue
          %}
        STR
      end

      it "has warns for s/r conflicts and r/r conflicts" do
        grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:error)

        states.validate!(logger)
        expect(logger).not_to have_received(:error)
      end
    end
  end
end
