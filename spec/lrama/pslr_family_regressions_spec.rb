# frozen_string_literal: true

RSpec.describe "PSLR family regressions" do
  def build_grammar(source, path)
    grammar = Lrama::Parser.new(source, path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end

  def compute_ielr_and_pslr(grammar)
    ielr_states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    ielr_states.compute
    ielr_states.compute_ielr

    pslr_states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    pslr_states.compute
    pslr_states.compute_pslr

    [ielr_states, pslr_states]
  end

  def acceptable_tokens(states, state)
    states.send(:acceptable_tokens_for_pslr, state).to_a
  end

  describe "pure-reduce profile" do
    let(:grammar) do
      build_grammar(<<~GRAMMAR, "states/pslr_pure_reduce.y")
        %define lr.type pslr
        %token-pattern RSHIFT />>/
        %token-pattern RANGLE />/
        %token-pattern ID /[a-z]+/
        %lex-prec RANGLE -s RSHIFT

        %%

        program
          : templ
          | rshift_expr
          ;

        templ
          : a RANGLE
          ;

        rshift_expr
          : a RSHIFT ID
          ;

        a
          : ID
          ;
      GRAMMAR
    end

    it "keeps pure reduce states scanner-compatible without forcing a split" do
      ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

      reduce_state = pslr_states.states.find do |state|
        state.reduces.any? { |reduce| reduce.rule.display_name == "a -> ID" }
      end

      expect(pslr_states.states_count).to eq(ielr_states.states_count)
      expect(pslr_states.pslr_inadequacies).to be_empty
      expect(acceptable_tokens(pslr_states, reduce_state)).to contain_exactly("RANGLE", "RSHIFT")
    end
  end

  describe "chained keyword split" do
    let(:grammar) do
      build_grammar(<<~GRAMMAR, "states/pslr_keyword_context.y")
        %define lr.type pslr
        %token-pattern P /p/
        %token-pattern Q /q/
        %token-pattern X /x/
        %token-pattern IF /if/
        %token-pattern ID /[a-z]+/
        %lex-prec IF - ID

        %%

        program
          : kw_context
          | id_context
          ;

        kw_context
          : P shared IF
          ;

        id_context
          : Q shared ID
          ;

        shared
          : n1
          ;

        n1
          : n2
          ;

        n2
          : X
          ;
      GRAMMAR
    end

    it "splits every chained reduce state by scanner profile" do
      ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

      reduce_states = pslr_states.states
        .select { |state| state.reduces.any? }
        .group_by { |state| state.reduces.first.rule.display_name }

      expect(pslr_states.states_count).to be > ielr_states.states_count
      expect(pslr_states.pslr_inadequacies).to be_empty

      ["shared -> n1", "n1 -> n2", "n2 -> X"].each do |rule_name|
        states_for_rule = reduce_states.fetch(rule_name)
        token_sets = states_for_rule.map { |state| acceptable_tokens(pslr_states, state) }

        expect(states_for_rule.size).to eq(2)
        expect(states_for_rule.count(&:split_state?)).to eq(1)
        expect(token_sets.any? { |set| set.include?("IF") && !set.include?("ID") }).to be(true)
        expect(token_sets.any? { |set| set.include?("ID") && !set.include?("IF") }).to be(true)
      end
    end
  end

  describe "chained shift/angle split" do
    let(:grammar) do
      build_grammar(<<~GRAMMAR, "states/pslr_shift_chain.y")
        %define lr.type pslr
        %token-pattern LT /</
        %token-pattern START /@/
        %token-pattern MARK /#/
        %token-pattern RSHIFT />>/
        %token-pattern RANGLE />/
        %token-pattern ID /[a-z]+/
        %lex-prec RANGLE -s RSHIFT

        %%

        program
          : template_expr
          | shift_expr
          ;

        template_expr
          : LT shared RANGLE
          ;

        shift_expr
          : START shared RSHIFT ID
          ;

        shared
          : n1
          ;

        n1
          : n2
          ;

        n2
          : MARK
          ;
      GRAMMAR
    end

    it "splits every chained reduce state by shift/angle scanner profile" do
      ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

      reduce_states = pslr_states.states
        .select { |state| state.reduces.any? }
        .group_by { |state| state.reduces.first.rule.display_name }

      expect(pslr_states.states_count).to be > ielr_states.states_count
      expect(pslr_states.pslr_inadequacies).to be_empty

      ["shared -> n1", "n1 -> n2", "n2 -> MARK"].each do |rule_name|
        states_for_rule = reduce_states.fetch(rule_name)
        token_sets = states_for_rule.map { |state| acceptable_tokens(pslr_states, state) }

        expect(states_for_rule.size).to eq(2)
        expect(states_for_rule.count(&:split_state?)).to eq(1)
        expect(token_sets.any? { |set| set.include?("RANGLE") && !set.include?("RSHIFT") }).to be(true)
        expect(token_sets.any? { |set| set.include?("RSHIFT") && !set.include?("RANGLE") }).to be(true)
      end
    end
  end

  describe "mixed families" do
    {
      "empty shared wrapper" => {
        path: "states/pslr_mixed_empty.y",
        grammar: <<~GRAMMAR,
          %define lr.type pslr
          %token-pattern LT /</
          %token-pattern START /@/
          %token-pattern P /p/
          %token-pattern Q /q/
          %token-pattern MARK /#/
          %token-pattern IF /if/
          %token-pattern ID /[a-z]+/
          %token-pattern RSHIFT />>/
          %token-pattern RANGLE />/
          %lex-prec IF - ID
          %lex-prec RANGLE -s RSHIFT

          %%

          program
            : kw
            | ident
            | templ
            | shift_expr
            ;

          kw
            : P shared IF
            ;

          ident
            : Q shared ID
            ;

          templ
            : LT shared RANGLE
            ;

          shift_expr
            : START shared RSHIFT ID
            ;

          shared
            : opt n1
            ;

          opt
            :
            ;

          n1
            : MARK
            ;
        GRAMMAR
      },
      "chain2 shared wrapper" => {
        path: "states/pslr_mixed_chain2.y",
        grammar: <<~GRAMMAR,
          %define lr.type pslr
          %token-pattern LT /</
          %token-pattern START /@/
          %token-pattern P /p/
          %token-pattern Q /q/
          %token-pattern MARK /#/
          %token-pattern IF /if/
          %token-pattern ID /[a-z]+/
          %token-pattern RSHIFT />>/
          %token-pattern RANGLE />/
          %lex-prec IF - ID
          %lex-prec RANGLE -s RSHIFT

          %%

          program
            : kw
            | ident
            | templ
            | shift_expr
            ;

          kw
            : P shared IF
            ;

          ident
            : Q shared ID
            ;

          templ
            : LT shared RANGLE
            ;

          shift_expr
            : START shared RSHIFT ID
            ;

          shared
            : n1
            ;

          n1
            : n2
            ;

          n2
            : MARK
            ;
        GRAMMAR
      }
    }.each do |label, attrs|
      it "keeps #{label} scanner-compatible" do
        grammar = build_grammar(attrs[:grammar], attrs[:path])
        ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

        expect(pslr_states.states_count).to be > ielr_states.states_count
        expect(pslr_states.pslr_inadequacies).to be_empty
      end
    end
  end
end
