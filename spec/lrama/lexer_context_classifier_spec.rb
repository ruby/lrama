# frozen_string_literal: true

RSpec.describe Lrama::LexerContextClassifier do
  include PslrFamilyHelper

  # Helper to build a classifier with standard CRuby-like contexts
  def build_classifier_with_contexts
    lexer_contexts = {}
    [
      ["BEG", %w[keyword_if keyword_unless keyword_while keyword_do tPLUS tMINUS tLPAREN tLBRACK tLBRACE]],
      ["CMDARG", %w[tIDENTIFIER tFID tCONSTANT]],
      ["END", %w[tINTEGER tFLOAT tSTRING_END keyword_end tRPAREN tRBRACK tRBRACE]],
      ["ENDFN", %w[keyword_def]],
      ["DOT", %w[tDOT tCOLON2 tANDDOT]],
    ].each_with_index do |(name, syms), idx|
      lc = Lrama::Grammar::LexerContext.new(name: name, index: idx)
      syms.each do |s|
        lc.add_symbols([double("token", s_value: s)])
      end
      lexer_contexts[name] = lc
    end
    described_class.new(lexer_contexts)
  end

  describe "context bitmask assignment" do
    it "assigns non-overlapping bitmask flags by definition order" do
      classifier = build_classifier_with_contexts
      bitmasks = classifier.contexts.map(&:bitmask)

      # All bitmasks should be powers of 2
      bitmasks.each do |bm|
        expect(bm).to be > 0
        expect(bm & (bm - 1)).to eq(0), "#{bm} is not a power of 2"
      end

      # No two should overlap
      bitmasks.combination(2).each do |a, b|
        expect(a & b).to eq(0), "Bitmasks #{a} and #{b} overlap"
      end
    end
  end

  describe ".context_name" do
    let(:lexer_contexts) do
      lcs = {}
      lc = Lrama::Grammar::LexerContext.new(name: "BEG", index: 0)
      lcs["BEG"] = lc
      lc2 = Lrama::Grammar::LexerContext.new(name: "CMDARG", index: 1)
      lcs["CMDARG"] = lc2
      lcs
    end

    it "returns UNKNOWN for 0" do
      expect(described_class.context_name(0, lexer_contexts)).to eq("UNKNOWN")
    end

    it "returns single context name for single flag" do
      expect(described_class.context_name(0x01, lexer_contexts)).to eq("BEG")
      expect(described_class.context_name(0x02, lexer_contexts)).to eq("CMDARG")
    end

    it "returns combined name for multiple flags" do
      name = described_class.context_name(0x01 | 0x02, lexer_contexts)
      expect(name).to include("BEG")
      expect(name).to include("CMDARG")
    end
  end

  describe "#classify_symbol_context" do
    let(:classifier) { build_classifier_with_contexts }

    it "classifies operator-like terminals" do
      %w[tPLUS tMINUS].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        # BEG = 1 << 0 = 0x01
        expect(ctx).to eq(0x01), "Expected #{name} to be BEG"
      end
    end

    it "classifies identifier terminals as CMDARG" do
      %w[tIDENTIFIER tFID tCONSTANT].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        # CMDARG = 1 << 1 = 0x02
        expect(ctx).to eq(0x02), "Expected #{name} to be CMDARG"
      end
    end

    it "classifies literal terminals as END" do
      %w[tINTEGER tFLOAT tSTRING_END].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        # END = 1 << 2 = 0x04
        expect(ctx).to eq(0x04), "Expected #{name} to be END"
      end
    end

    it "classifies keyword_def as ENDFN" do
      sym = double("symbol", id: double("id", s_value: "keyword_def"), term?: true)
      ctx = classifier.classify_symbol_context(sym)
      # ENDFN = 1 << 3 = 0x08
      expect(ctx).to eq(0x08)
    end

    it "classifies dot tokens as DOT" do
      %w[tDOT tCOLON2 tANDDOT].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        # DOT = 1 << 4 = 0x10
        expect(ctx).to eq(0x10), "Expected #{name} to be DOT"
      end
    end

    it "classifies open brackets as BEG" do
      %w[tLPAREN tLBRACK tLBRACE].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        expect(ctx).to eq(0x01), "Expected #{name} to be BEG"
      end
    end

    it "classifies close brackets as END" do
      %w[tRPAREN tRBRACK tRBRACE].each do |name|
        sym = double("symbol", id: double("id", s_value: name), term?: true)
        ctx = classifier.classify_symbol_context(sym)
        expect(ctx).to eq(0x04), "Expected #{name} to be END"
      end
    end

    it "returns 0 for unknown symbols" do
      sym = double("symbol", id: double("id", s_value: "unknown_token"), term?: true)
      ctx = classifier.classify_symbol_context(sym)
      expect(ctx).to eq(0)
    end
  end

  describe "#classify with grammar-defined contexts" do
    context "with %lexer-context directives" do
      let(:grammar) do
        build_grammar(<<~GRAMMAR, "lexer_context/basic.y")
          %define lr.type pslr
          %token-pattern IF /if/
          %token-pattern ID /[a-z]+/
          %lex-prec ID <~ IF

          %lexer-context BEG IF
          %lexer-context CMDARG ID

          %%

          program
            : expr
            ;

          expr
            : ID
            | expr '+' expr
            ;
        GRAMMAR
      end

      it "classifies states without errors" do
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        states.states.each do |state|
          expect(state.lexer_context).not_to be_nil
        end
      end
    end

    context "with operator-heavy grammar" do
      let(:grammar) do
        build_grammar(<<~GRAMMAR, "lexer_context/operators.y")
          %define lr.type pslr
          %token-pattern PLUS /\\+/
          %token-pattern STAR /\\*/
          %token-pattern ID /[a-z]+/
          %token-pattern NUM /[0-9]+/

          %lexer-context BEG PLUS STAR
          %lexer-context CMDARG ID
          %lexer-context END NUM

          %%

          program
            : expr
            ;

          expr
            : NUM
            | ID
            | expr PLUS expr
            | expr STAR expr
            ;
        GRAMMAR
      end

      it "classifies all states" do
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        states.states.each do |state|
          expect(state.lexer_context).not_to be_nil
        end
      end
    end
  end

  describe "integration with States" do
    context "lexer_context_enabled?" do
      it "returns false when no %lexer-context directives" do
        grammar = build_grammar(<<~GRAMMAR, "lexer_context/no_ctx.y")
          %define lr.type pslr
          %token-pattern ID /[a-z]+/

          %%

          program : ID ;
        GRAMMAR

        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        expect(states.lexer_context_enabled?).to eq(false)
      end

      it "returns true when %lexer-context directives are present" do
        grammar = build_grammar(<<~GRAMMAR, "lexer_context/with_ctx.y")
          %define lr.type pslr
          %token-pattern ID /[a-z]+/

          %lexer-context BEG ID

          %%

          program : ID ;
        GRAMMAR

        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        expect(states.lexer_context_enabled?).to eq(true)
      end
    end

    context "lexer_context_table" do
      it "returns an array with one entry per state" do
        grammar = build_grammar(<<~GRAMMAR, "lexer_context/table.y")
          %define lr.type pslr
          %token-pattern ID /[a-z]+/
          %token-pattern NUM /[0-9]+/

          %lexer-context BEG ID
          %lexer-context END NUM

          %%

          program
            : expr
            ;

          expr
            : NUM
            | ID
            | expr '+' expr
            ;
        GRAMMAR

        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        table = states.lexer_context_table
        expect(table.size).to eq(states.states_count)
        expect(table.all? { |v| v.is_a?(Integer) }).to eq(true)
      end
    end
  end

  describe "context-based state splitting" do
    context "with operator vs identifier predecessor contexts" do
      let(:grammar) do
        build_grammar(<<~GRAMMAR, "lexer_context/split_expr.y")
          %define lr.type pslr
          %token-pattern tPLUS /\\+/
          %token-pattern tSTAR /\\*/
          %token-pattern tIDENTIFIER /[a-z]+/
          %token-pattern tINTEGER /[0-9]+/

          %lexer-context BEG tPLUS tSTAR
          %lexer-context CMDARG tIDENTIFIER
          %lexer-context END tINTEGER

          %%

          program
            : expr
            ;

          expr
            : tINTEGER
            | tIDENTIFIER
            | expr tPLUS expr
            | expr tSTAR expr
            ;
        GRAMMAR
      end

      it "classifies all states with non-nil context" do
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        states.states.each do |state|
          expect(state.lexer_context).not_to be_nil,
            "State #{state.id} has nil lexer_context"
        end
      end

      it "has BEG context after operators" do
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        # Find states after tPLUS or tSTAR
        operator_target_states = []
        states.states.each do |state|
          state.term_transitions.each do |shift|
            name = shift.next_sym.id.s_value
            if name == "tPLUS" || name == "tSTAR"
              operator_target_states << shift.to_state
            end
          end
        end

        lexer_contexts = grammar.lexer_contexts
        beg_mask = lexer_contexts["BEG"].bitmask

        operator_target_states.each do |target|
          ctx = target.lexer_context || 0
          ctx_name = described_class.context_name(ctx, lexer_contexts)
          expect(ctx & beg_mask).not_to eq(0),
            "State #{target.id} after operator should have BEG context, got #{ctx_name}"
        end
      end
    end

    context "with def keyword creating ENDFN context" do
      let(:grammar) do
        build_grammar(<<~GRAMMAR, "lexer_context/endfn.y")
          %define lr.type pslr
          %token-pattern keyword_def /def/
          %token-pattern keyword_end /end/
          %token-pattern tIDENTIFIER /[a-z]+/
          %token-pattern tINTEGER /[0-9]+/

          %lexer-context ENDFN keyword_def
          %lexer-context END keyword_end tINTEGER
          %lexer-context CMDARG tIDENTIFIER

          %%

          program
            : defn
            ;

          defn
            : keyword_def tIDENTIFIER keyword_end
            ;
        GRAMMAR
      end

      it "marks state after keyword_def as ENDFN" do
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        states.compute_pslr

        lexer_contexts = grammar.lexer_contexts
        endfn_mask = lexer_contexts["ENDFN"].bitmask

        # Find state reached after keyword_def
        def_target = nil
        states.states.each do |state|
          state.term_transitions.each do |shift|
            if shift.next_sym.id.s_value == "keyword_def"
              def_target = shift.to_state
            end
          end
        end

        expect(def_target).not_to be_nil
        ctx = def_target.lexer_context || 0
        ctx_name = described_class.context_name(ctx, lexer_contexts)
        expect(ctx & endfn_mask).not_to eq(0),
          "State after keyword_def should have ENDFN context, got #{ctx_name}"
      end
    end
  end

  describe "existing PSLR tests still pass" do
    context "pure reduce profile" do
      let(:grammar) do
        build_grammar(<<~GRAMMAR, "states/pslr_pure_reduce.y")
          %define lr.type pslr
          %token-pattern RSHIFT />>/
          %token-pattern RANGLE />/
          %token-pattern ID /[a-z]+/
          %lex-prec RANGLE -~ RSHIFT

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

      it "does not break PSLR" do
        _, pslr_states = compute_ielr_and_pslr(grammar)
        expect(pslr_states.pslr_inadequacies).to be_empty
      end
    end

    context "chained keyword split" do
      let(:grammar) do
        build_grammar(keyword_context_source(depth: 2), "states/pslr_keyword_ctx.y")
      end

      it "does not break PSLR split" do
        ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

        expect(pslr_states.states_count).to be > ielr_states.states_count
        expect(pslr_states.pslr_inadequacies).to be_empty
      end
    end
  end
end
