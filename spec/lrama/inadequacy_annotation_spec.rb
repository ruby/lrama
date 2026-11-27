# frozen_string_literal: true

RSpec.describe Lrama::State::InadequacyAnnotation do
  describe '#dominant_contribution' do
    [
      ['higher precedence before nonassociativity', "%nonassoc 'b'\n%precedence HIGH",
       ["empty: %empty %prec HIGH;", "direct: 'a' %prec 'b';"], ['direct', 'empty']],
      ['nonassociativity before higher precedence', "%nonassoc 'b'\n%precedence HIGH",
       ["direct: 'a' %prec 'b';", "empty: %empty %prec HIGH;"], []],
      ['left associativity before lower precedence', "%precedence LOW\n%left 'b'",
       ["empty: %empty %prec 'b';", "direct: 'a' %prec LOW;"], ['direct', 'empty']],
      ['lower precedence before left associativity', "%precedence LOW\n%left 'b'",
       ["direct: 'a' %prec LOW;", "empty: %empty %prec 'b';"], ['empty']],
      ['nonassociativity with another reduction', "%precedence LOW\n%nonassoc 'b'",
       ["empty: %empty %prec 'b';", "direct: 'a' %prec LOW;"], []],
      ['right associativity', "%right 'b'",
       ["empty: %empty %prec 'b';", "direct: 'a' %prec 'b';"], ['shift']],
      ['unresolved equal precedence', "%precedence 'b'",
       ["empty: %empty %prec 'b';", "direct: 'a' %prec 'b';"], ['shift', 'direct', 'empty']],
    ].each do |description, precedences, rules, expected|
      it "matches state conflict resolution for #{description}" do
        grammar = Lrama::Parser.new(<<~GRAMMAR, 'annotation_conflicts.y').parse
          #{precedences}
          %%
          start: 'a' empty 'b' 'x' | direct 'b' 'y' | 'a' 'b' 'z';
          #{rules.join("\n")}
        GRAMMAR
        grammar.prepare
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        state = states.states.find { |s| s.reduces.length == 2 }
        token = grammar.find_symbol_by_s_value!("'b'")
        actions = state.inadequacy_list.fetch(token)
        annotation = described_class.new(state, token, actions, actions.map { |action| [action, nil] }.to_h)

        original_actions = actions.dup
        result = annotation.dominant_contribution({}, [])

        expect(result.map { |action| action.is_a?(Lrama::State::Action::Shift) ? 'shift' : action.rule.lhs.name }).to eq(expected)
        expect(annotation.actions).to eq(original_actions)
      end
    end

    it 'distinguishes a nonassociative error from a reduction when comparing states' do
      grammar = Lrama::Parser.new(<<~GRAMMAR, 'annotation_conflicts.y').parse
        %nonassoc 'b'
        %precedence HIGH
        %%
        start: first 'b' | second 'b' | 'a' 'b';
        first: 'a' %prec 'b';
        second: 'a' %prec HIGH;
      GRAMMAR
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      state = states.states.find { |s| s.reduces.length == 2 }
      token = grammar.find_symbol_by_s_value!("'b'")
      actions = state.inadequacy_list.fetch(token)
      first = actions.find { |action| action.is_a?(Lrama::State::Action::Reduce) && action.rule.lhs.name == 'first' }
      matrix = actions.map { |action| [action, action == first ? 1 : nil] }.to_h
      annotation = described_class.new(state, token, actions, matrix)
      state.annotation_list << annotation
      present = state.kernels.map { |item| [item, 1 << token.number] }.to_h
      absent = state.kernels.map { |item| [item, 0] }.to_h
      state.item_lookahead_set = present
      state.lookaheads_recomputed = true

      expect(state.is_compatible?(absent)).to be(false)
      expect(annotation.dominant_contribution(present, state.kernels)).to eq([])
      expect(annotation.dominant_contribution(absent, state.kernels).map { |action| action.rule.lhs.name }).to eq(['second'])
    end
  end
end
