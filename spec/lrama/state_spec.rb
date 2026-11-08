# frozen_string_literal: true

RSpec.describe Lrama::State do
  let(:rule) do
    grammar = Lrama::Parser.new("%%\nstart: 'a' 'b';\n", "state.y").parse
    grammar.prepare
    grammar.rules.last
  end
  let(:token) { rule.rhs.first }
  let(:state) { described_class.new(0, token, []) }
  let(:origin) { described_class.new(1, token, []) }
  let(:item) { Lrama::State::Item.new(rule: rule, position: 0) }
  let(:next_item) { item.new_by_next_position }
  let(:actions) { [Lrama::State::Action::Reduce.new(next_item)] }

  def annotation(contributions, from: origin, on: token, with: actions)
    Lrama::State::InadequacyAnnotation.new(from, on, with, { with.first => contributions })
  end

  describe "lookaheads for duplicate rules" do
    let(:grammar) do
      grammar = Lrama::Parser.new("%%\nstart: 'a' | 'a';\n", "duplicate.y").parse
      grammar.prepare
      grammar
    end
    let(:rules) { grammar.rules.last(2) }
    let(:state) do
      items = rules.map { |rule| Lrama::State::Item.new(rule: rule, position: rule.rhs.length) }
      state = described_class.new(0, rules.first.rhs.first, items)
      state.compute_transitions_and_reduces
      state
    end

    it "assigns lookaheads to the specified rule ID" do
      state.set_look_ahead(rules.first, [grammar.eof_symbol])
      state.set_look_ahead(rules.last, [])

      expect(state.reduces.map(&:look_ahead)).to eq([[grammar.eof_symbol], []])
    end

    it "assigns lookahead sources to the specified rule ID" do
      sources = { grammar.eof_symbol => [] }
      state.set_look_ahead_sources(rules.first, sources)
      state.set_look_ahead_sources(rules.last, {})

      expect(state.reduces.map(&:look_ahead_sources)).to eq([sources, {}])
    end
  end

  describe "#transitions_by_symbol_number" do
    it "distinguishes terminal and nonterminal token IDs and refreshes redirected gotos" do
      grammar = Lrama::Parser.new("%token A 1\n%%\nstart: A;\n", "transitions.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      initial = states.states.first
      terminal = grammar.find_symbol_by_s_value!("A")
      nonterminal = grammar.find_symbol_by_s_value!("start")
      expect(terminal.token_id).to eq(nonterminal.token_id)
      index = initial.transitions_by_symbol_number
      shift = index.fetch(terminal.number)
      goto = index.fetch(nonterminal.number)
      expect(shift).to be_a(Lrama::State::Action::Shift)
      expect(goto).to be_a(Lrama::State::Action::Goto)
      replacement = described_class.new(states.states_count, nonterminal, goto.to_state.kernels)

      initial.update_transition(goto, replacement)

      updated = initial.transitions_by_symbol_number
      expect(updated.fetch(terminal.number)).to equal(shift)
      expect(updated.fetch(nonterminal.number).to_state).to equal(replacement)
      expect(updated.fetch(nonterminal.number)).not_to equal(goto)
    end
  end

  describe "#update_transition" do
    it "preserves transition order while the transitions are being visited" do
      grammar = Lrama::Parser.new("%%\nstart: 'a' 'b' | 'a' 'c' | 'a' 'd';\n", "transitions.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      current = states.states.first.term_transitions.first.to_state
      first = current.transitions.first
      original_order = current.transitions.map(&:next_sym)
      replacement = described_class.new(states.states_count, first.next_sym, first.to_state.kernels)
      visited = []

      current.transitions.each do |transition|
        visited << transition.next_sym
        current.update_transition(transition, replacement) if transition.equal?(first)
      end

      expect(visited).to eq(original_order)
      expect(current.transitions.map(&:next_sym)).to eq(original_order)
      expect(current.transitions.first.to_state).to equal(replacement)
    end

    it "replaces the current transition and transfers its caches when given an earlier transition object" do
      grammar = Lrama::Parser.new("%%\nstart: 'a';\n", "transitions.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      current = states.states.first
      transition = current.nterm_transitions.first
      original_count = current.transitions.length
      kernels = { current.kernels.first => true }
      tokens = [grammar.rules.last.rhs.first]
      current.follow_kernel_items[transition] = kernels
      current.always_follows[transition] = tokens
      first = described_class.new(states.states_count, transition.next_sym, transition.to_state.kernels)
      second = described_class.new(states.states_count + 1, transition.next_sym, transition.to_state.kernels)

      current.update_transition(transition, first)
      current.update_transition(transition, second)

      updated = current.transitions_by_symbol_number.fetch(transition.next_sym.number)
      expect(current.transitions.length).to eq(original_count)
      expect(updated.to_state).to equal(second)
      expect(current.follow_kernel_items[updated]).to equal(kernels)
      expect(current.always_follows[updated]).to equal(tokens)
    end
  end

  describe "#append_predecessor" do
    it "retains distinct objects with the same ID and preserves insertion order" do
      other = described_class.new(origin.id, token, [])

      [origin, other, origin, other].each { |predecessor| state.append_predecessor(predecessor) }

      expect(state.predecessors.map(&:object_id)).to eq([origin.object_id, other.object_id])
    end
  end

  describe "#predecessors_with_item" do
    it "retains matching rules with different IDs and excludes unequal rules at the same location" do
      equivalent_rule = rule.dup
      equivalent_rule.id += 100
      equivalent = Lrama::State::Item.new(rule: equivalent_rule, position: item.position)
      different_rule = rule.dup
      different_rule.rhs = rule.rhs.reverse
      different = Lrama::State::Item.new(rule: different_rule, position: item.position)
      predecessor = described_class.new(1, token, [item, equivalent, different])
      state.append_predecessor(predecessor)

      expect(state.predecessors_with_item(next_item)).to eq([[predecessor, item], [predecessor, equivalent]])
    end

    it "rebuilds the item index when the closure is assigned" do
      state.append_predecessor(origin)
      expect(state.predecessors_with_item(next_item)).to eq([])

      origin.closure = [item]

      expect(state.predecessors_with_item(next_item)).to eq([[origin, item]])
    end

    it "does not compare items from unrelated source locations" do
      unrelated_rule = rule.dup
      unrelated_rule.lineno += 1
      unrelated = Lrama::State::Item.new(rule: unrelated_rule, position: item.position)
      predecessor = described_class.new(1, token, [unrelated, item])
      state.append_predecessor(predecessor)
      expect(unrelated_rule).not_to receive(:==)

      expect(state.predecessors_with_item(next_item)).to eq([[predecessor, item]])
    end
  end

  describe "#predecessor_dependencies" do
    let(:rule) do
      grammar = Lrama::Parser.new("%%\nstart: 'a' 'b' target;\ntarget: 'c';\n", "origins.y").parse
      grammar.prepare
      grammar.rules[1]
    end
    let(:first) { described_class.new(1, token, [item]) }
    let(:second) { described_class.new(2, token, [item]) }
    let(:left) { described_class.new(3, token, [next_item]) }
    let(:right) { described_class.new(4, token, [next_item]) }
    let(:tail_item) { next_item.new_by_next_position }
    let(:tail) { described_class.new(5, rule.rhs[1], [tail_item]) }
    let(:first_goto) { Lrama::State::Action::Goto.new(first, rule.lhs, [], tail) }
    let(:second_goto) { Lrama::State::Action::Goto.new(second, rule.lhs, [], tail) }
    let(:target_goto) { Lrama::State::Action::Goto.new(tail, rule.rhs.last, [], tail) }

    before do
      [left, right].each do |middle|
        middle.append_predecessor(first)
        middle.append_predecessor(second)
      end
      tail.append_predecessor(left)
      tail.append_predecessor(right)
      allow(first).to receive(:transitions).and_return([first_goto])
      allow(second).to receive(:transitions).and_return([second_goto])
    end

    it "visits converging origins once in the existing depth-first order" do
      expect(tail.predecessor_dependencies(target_goto)).to eq([second_goto, first_goto])
    end

    it "shares intermediate origins across dependency queries" do
      cache = {}
      tail.predecessor_dependencies(target_goto, cache)
      expect(left).not_to receive(:predecessors_with_item)
      expect(right).not_to receive(:predecessors_with_item)

      expect(tail.predecessor_dependencies(target_goto, cache)).to eq([second_goto, first_goto])
    end

    it "uses fresh origins for a new relation construction after predecessors change" do
      tail.predecessor_dependencies(target_goto)
      third = described_class.new(6, token, [item])
      third_goto = Lrama::State::Action::Goto.new(third, rule.lhs, [], tail)
      allow(third).to receive(:transitions).and_return([third_goto])
      right.append_predecessor(third)

      expect(tail.predecessor_dependencies(target_goto)).to eq([third_goto, second_goto, first_goto])
    end

    it "does not use a position-zero kernel as an origin" do
      initial = described_class.new(0, token, [item])
      transition = Lrama::State::Action::Goto.new(initial, item.next_sym, [], tail)
      allow(item).to receive(:symbols_after_transition).and_return([])

      expect(initial.predecessor_dependencies(transition)).to eq([])
    end

    it "finds origins along a long predecessor chain without recursion" do
      grammar = Lrama::Parser.new("%%\nstart: #{Array.new(2000, "'a'").join(' ')};\n", "long.y").parse
      grammar.prepare
      long_rule = grammar.rules[1]
      chain = (0..2000).map do |position|
        kernel = Lrama::State::Item.new(rule: long_rule, position: position)
        described_class.new(position, token, [kernel])
      end
      chain.each_cons(2) { |previous, following| following.append_predecessor(previous) }

      expect(chain.last.item_origins(chain.last.kernels.first, {})).to eq([[chain.first, chain.first.kernels.first]])
    end
  end

  describe "#internal_dependencies" do
    let(:initial) do
      grammar = Lrama::Parser.new(<<~GRAMMAR, "internal.y").parse
        %%
        start: x | y;
        x: target optional | target | %empty;
        y: target 'z';
        target: 't';
        optional: %empty;
      GRAMMAR
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.states.first
    end

    it "includes only position-zero items with a nullable suffix and removes duplicate symbols" do
      target_goto = initial.nterm_transitions.find { |transition| transition.next_sym.name == "target" }
      x_goto = initial.nterm_transitions.find { |transition| transition.next_sym.name == "x" }

      expect(initial.internal_dependencies(target_goto)).to eq([x_goto])
    end

    it "indexes items once across all goto symbols" do
      initial.items.each { |entry| expect(entry).to receive(:next_sym).at_most(1).times.and_call_original }

      initial.nterm_transitions.each { |transition| initial.internal_dependencies(transition) }
    end
  end

  describe "#is_compatible?" do
    let(:other_action) { Lrama::State::Action::Reduce.new(item) }
    let(:entry) do
      Lrama::State::InadequacyAnnotation.new(origin, token, actions + [other_action], {
        actions.first => { item => true }, other_action => { next_item => true },
      })
    end
    let(:current) { { item => [token], next_item => [] } }
    let(:incoming) { { item => [], next_item => [token] } }

    before do
      state.annotation_list << entry
      state.item_lookahead_set = current
      state.lookaheads_recomputed = true
    end

    it "accepts unrecomputed states without computing contributions" do
      state.lookaheads_recomputed = false
      expect(entry).not_to receive(:dominant_contribution)

      expect(state.is_compatible?(incoming)).to be(true)
    end

    it "accepts equal lookahead sets without computing contributions" do
      expect(entry).not_to receive(:dominant_contribution)

      expect(state.is_compatible?(current.transform_values(&:dup))).to be(true)
    end

    it "reuses stored contributions and invalidates them when lookaheads are assigned" do
      expect(entry).to receive(:dominant_contribution).with(current).once.and_call_original
      expect(entry).to receive(:dominant_contribution).with(incoming).exactly(3).times.and_call_original
      replacement = { item => [], next_item => [token, token] }
      expect(entry).to receive(:dominant_contribution).with(replacement).once.and_call_original

      2.times { expect(state.is_compatible?(incoming)).to be(false) }
      state.item_lookahead_set = replacement

      expect(state.is_compatible?(incoming)).to be(true)
    end

    it "caches nil stored contributions as compatible" do
      empty = { item => [], next_item => [] }
      state.item_lookahead_set = empty
      expect(entry).to receive(:dominant_contribution).with(empty).once.and_call_original

      2.times { expect(state.is_compatible?(incoming)).to be(true) }
    end

    it "shares incoming contributions across isocores, including nil results" do
      split = described_class.new(2, token, state.kernels)
      split.lalr_isocore = state
      split.item_lookahead_set = incoming
      split.lookaheads_recomputed = true
      empty = { item => [], next_item => [] }
      cache = {}
      expect(entry).to receive(:dominant_contribution).with(current).once.and_call_original
      expect(entry).to receive(:dominant_contribution).with(incoming).once.and_call_original
      expect(entry).to receive(:dominant_contribution).with(empty).once.and_call_original

      expect(state.is_compatible?(empty, cache)).to be(true)
      expect(split.is_compatible?(empty, cache)).to be(true)
    end

    it "does not treat an empty dominant contribution as nil" do
      allow(entry).to receive(:dominant_contribution).with(current).and_return([])
      allow(entry).to receive(:dominant_contribution).with(incoming).and_return(actions)

      2.times { expect(state.is_compatible?(incoming)).to be(false) }
    end
  end

  describe "#lookahead_set_filters" do
    let(:state) { described_class.new(0, token, [item, next_item]) }

    it "retains annotation order and duplicates without repeating a token for multiple actions" do
      first = annotation({ item => false, next_item => true })
      first.contribution_matrix[Lrama::State::Action::Reduce.new(item)] = { item => true, next_item => true }
      state.annotation_list.concat([
        first,
        annotation(nil),
        annotation({ item => true, next_item => false }, on: rule.rhs.last),
        annotation({ item => true }),
      ])

      expect(state.lookahead_set_filters).to eq({ item => [token, rule.rhs.last, token], next_item => [token] })
    end

    it "includes empty filters for kernels without contributions" do
      state.annotation_list << annotation({ item => false, next_item.new_by_next_position => true })

      expect(state.lookahead_set_filters).to eq({ item => [], next_item => [] })
    end

    it "shares the LALR isocore's filters with split states" do
      state.annotation_list << annotation({ next_item => true })
      split = described_class.new(2, token, state.kernels)
      split.lalr_isocore = state

      expect(split.lookahead_set_filters).to equal(state.lookahead_set_filters)
      expect(split.lookahead_set_filters).to eq({ item => [], next_item => [token] })
    end
  end

  describe "#propagate_lookaheads" do
    it "skips goto follow sets when a first-position kernel has an empty filter" do
      successor = described_class.new(1, token, [next_item])
      expect(state).not_to receive(:goto_follow_set)

      expect(state.propagate_lookaheads(successor)).to eq({ next_item => [] })
    end

    it "skips predecessor lookaheads when a later kernel has an empty filter" do
      successor = described_class.new(1, token, [next_item.new_by_next_position])
      expect(state).not_to receive(:item_lookahead_set)

      expect(state.propagate_lookaheads(successor)).to eq({ successor.kernels.first => [] })
    end

    it "filters both kinds of lookaheads while preserving their token order" do
      last_item = next_item.new_by_next_position
      predecessor = described_class.new(0, token, [next_item])
      successor = described_class.new(1, token, [next_item, last_item])
      successor.annotation_list.concat([
        annotation({ next_item => true, last_item => true }),
        annotation({ next_item => true, last_item => true }, on: rule.rhs.last),
      ])
      predecessor.item_lookahead_set = { next_item => [rule.rhs.last, token, token.dup] }
      allow(predecessor).to receive(:goto_follow_set).with(rule.lhs).and_return([rule.rhs.last, token, token])

      expect(predecessor.propagate_lookaheads(successor)).to eq({
        next_item => [rule.rhs.last, token], last_item => [rule.rhs.last, token],
      })
      expect(successor.lookahead_set_filters.values).to all(eq([token, rule.rhs.last]))
    end
  end

  describe "#annotate_manifestation" do
    it "keeps shifts unconditional and stores only completed matching kernels for nonempty reductions" do
      completed = next_item.new_by_next_position
      equivalent_rule = rule.dup
      equivalent_rule.id += 100
      equivalent = Lrama::State::Item.new(rule: equivalent_rule, position: completed.position)
      current = described_class.new(0, token, [next_item, completed, equivalent])
      shift = Lrama::State::Action::Shift.new(current, token, [], origin)
      reduce = Lrama::State::Action::Reduce.new(completed)
      allow(current).to receive(:inadequacy_list).and_return({ token => [shift, reduce] })

      current.annotate_manifestation

      expect(current.annotation_list.first.contribution_matrix).to eq({
        shift => nil, reduce => { completed => true, equivalent => true },
      })
    end

    it "does not mutate cached lhs contributions when merging annotations for empty reductions" do
      empty_rule = rule.dup
      empty_rule.rhs = []
      reduce = Lrama::State::Action::Reduce.new(Lrama::State::Item.new(rule: empty_rule, position: 0))
      contributions = { item => false }
      allow(state).to receive(:inadequacy_list).and_return({ token => [reduce] })
      allow(state).to receive(:lhs_contributions).with(rule.lhs, token).and_return(contributions)

      state.annotate_manifestation
      entry = state.annotation_list.first
      entry.merge_matrix([{ reduce => { item => true } }])

      expect(entry.contribution_matrix[reduce]).to eq({ item => true })
      expect(contributions).to eq({ item => false })
    end
  end

  describe "#annotate_predecessor" do
    let(:last_item) { next_item.new_by_next_position }
    let(:state) { described_class.new(2, token, [next_item, last_item]) }
    let(:predecessor) { described_class.new(0, token, [item, next_item]) }
    let(:other_action) { Lrama::State::Action::Reduce.new(last_item) }

    before do
      predecessor.lane_items[state] = [[item, next_item], [next_item, last_item]]
      predecessor.item_lookahead_set = { item => [], next_item => [token] }
    end

    it "propagates first-position lhs and later-position lookahead contributions, omitting false entries" do
      allow(predecessor).to receive(:lhs_contributions).with(rule.lhs, token).and_return({ item => true })
      state.annotation_list << annotation({ next_item => true, last_item => true })
      state.annotation_list << annotation({ next_item => false, last_item => true }, from: state)

      expect(state.annotate_predecessor(predecessor)).to be(true)

      expect(predecessor.annotation_list.map(&:contribution_matrix)).to eq([
        { actions.first => { item => true, next_item => true } },
        { actions.first => { next_item => true } },
      ])
      expect(predecessor.annotation_list.map(&:state)).to eq([origin, state])
    end

    it "shares the unconditional contribution check across actions" do
      state.annotation_list << Lrama::State::InadequacyAnnotation.new(origin, token, actions + [other_action], {
        actions.first => { next_item => true }, other_action => { next_item => true },
      })
      expect(predecessor).to receive(:lhs_contributions).with(rule.lhs, token).once.and_return({})

      state.annotate_predecessor(predecessor)

      expect(predecessor.annotation_list).to eq([])
    end

    it "uses separate checks for each token and refreshes them after a propagation call" do
      contributions = {}
      allow(predecessor).to receive(:lhs_contributions).with(rule.lhs, token).and_return(contributions)
      allow(predecessor).to receive(:lhs_contributions).with(rule.lhs, rule.rhs.last).and_return({ item => true })
      state.annotation_list << annotation({ next_item => true })
      state.annotation_list << annotation({ next_item => true }, on: rule.rhs.last)

      state.annotate_predecessor(predecessor)

      expect(predecessor.annotation_list.map(&:token)).to eq([rule.rhs.last])
      contributions[item] = true
      state.annotate_predecessor(predecessor)
      expect(predecessor.annotation_list.map(&:token)).to eq([rule.rhs.last, token])
    end

    it "does not treat noncontributing first-position kernels as unconditional" do
      state.annotation_list << annotation({ next_item => false, last_item => true })
      expect(predecessor).not_to receive(:lhs_contributions)

      state.annotate_predecessor(predecessor)

      expect(predecessor.annotation_list.first.contribution_matrix).to eq({ actions.first => { next_item => true } })
    end

    it "stops annotations with only always or never contributions" do
      state.annotation_list << Lrama::State::InadequacyAnnotation.new(origin, token, actions + [other_action], {
        actions.first => nil, other_action => { last_item => true },
      })
      predecessor.item_lookahead_set = { item => [], next_item => [] }

      expect(state.annotate_predecessor(predecessor)).to be(false)

      expect(predecessor.annotation_list).to eq([])
    end

    it "does not populate a shared empty-rule lhs contribution hash during propagation" do
      empty_rule = rule.dup
      empty_rule.rhs = []
      reduce = Lrama::State::Action::Reduce.new(Lrama::State::Item.new(rule: empty_rule, position: 0))
      contributions = {}
      existing = Lrama::State::InadequacyAnnotation.new(origin, token, [reduce, other_action], {
        reduce => contributions, other_action => {},
      })
      predecessor.annotation_list << existing
      state.annotation_list << Lrama::State::InadequacyAnnotation.new(origin, token, [reduce, other_action], {
        reduce => {}, other_action => { last_item => true },
      })

      state.annotate_predecessor(predecessor)

      expect(predecessor.annotation_list).to eq([existing])
      expect(existing.contribution_matrix[reduce]).to eq({ item => nil, next_item => nil })
      expect(contributions).to eq({})
      expect(existing.contribution_matrix[other_action]).to eq({ next_item => true })
    end
  end

  describe "#append_annotation_list" do
    it "matches state IDs and equal action arrays while retaining the existing annotation" do
      existing = annotation({ item => false, next_item => true })
      state.annotation_list << existing
      incoming = annotation({ item => true, next_item => false },
                            from: described_class.new(origin.id, token, []), with: actions.dup)
      propagating = [incoming]

      expect(state.append_annotation_list(propagating)).to be(true)

      expect(state.annotation_list).to eq([existing])
      expect(existing.contribution_matrix).to eq({ actions.first => { item => true, next_item => true } })
      expect(propagating).to eq([incoming])
    end

    it "keeps annotations for different states, token objects, or actions separate" do
      existing = annotation({ item => false })
      state.annotation_list << existing
      incoming = [
        annotation({ item => true }, from: described_class.new(2, token, [])),
        annotation({ item => true }, on: token.dup),
        annotation({ item => true }, with: [Lrama::State::Action::Reduce.new(next_item)]),
      ]

      expect(state.append_annotation_list(incoming)).to be(true)

      expect(state.annotation_list).to eq([existing] + incoming)
      expect(existing.contribution_matrix[actions.first][item]).to be(false)
    end

    it "merges all matching incoming annotations into only the first existing match" do
      first = annotation({ item => false, next_item => false })
      duplicate = annotation({ item => false, next_item => false })
      state.annotation_list.concat([first, duplicate])

      state.append_annotation_list([annotation({ item => true }), annotation({ next_item => true })])

      expect(state.annotation_list).to eq([first, duplicate])
      expect(first.contribution_matrix[actions.first]).to eq({ item => true, next_item => true })
      expect(duplicate.contribution_matrix[actions.first]).to eq({ item => false, next_item => false })
    end

    it "appends unmatched annotations in their original order, including duplicate keys" do
      existing = annotation({ item => false })
      state.annotation_list << existing
      first = annotation({ item => false }, from: described_class.new(2, token, []))
      second = annotation({ next_item => true }, on: rule.rhs.last)
      third = annotation({ item => true }, from: first.state)

      state.append_annotation_list([first, annotation({ item => true }), second, third])

      expect(state.annotation_list).to eq([existing, first, second, third])
      expect(first.contribution_matrix[actions.first][item]).to be(false)
      expect(existing.contribution_matrix[actions.first][item]).to be(true)
    end

    it "retains always contributions when conditional contributions arrive" do
      existing = annotation(nil)
      state.annotation_list << existing

      expect(state.append_annotation_list([annotation({ item => true }), annotation(nil)])).to be(false)

      expect(existing.contribution_matrix[actions.first]).to be_nil
      expect(existing.dominant_contribution({ item => [] })).to eq(actions)
    end

    it "replaces conditional contributions with always contributions and reports the change once" do
      existing = annotation({ item => true })
      state.annotation_list << existing

      expect(state.append_annotation_list([annotation(nil), annotation({ item => true })])).to be(true)
      expect(state.append_annotation_list([annotation(nil)])).to be(false)

      expect(existing.contribution_matrix[actions.first]).to be_nil
      expect(existing.dominant_contribution({ item => [] })).to eq(actions)
    end

    it "does not mutate contributions shared with another annotation" do
      contributions = { item => false }
      first = annotation(contributions)
      second = annotation(contributions, on: rule.rhs.last)
      state.annotation_list.concat([first, second])

      expect(state.append_annotation_list([annotation({ item => true })])).to be(true)

      expect(first.contribution_matrix[actions.first]).to eq({ item => true })
      expect(second.contribution_matrix[actions.first]).to eq({ item => false })
      expect(contributions).to eq({ item => false })
    end

    it "reports no change when no contributions are added" do
      state.annotation_list << annotation({ item => true })

      expect(state.append_annotation_list([annotation({ item => true })])).to be(false)
      expect(state.append_annotation_list([])).to be(false)
    end

    it "does not treat false, nil, or missing item contributions as changes" do
      existing = annotation({ item => false })
      state.annotation_list << existing

      expect(state.append_annotation_list([annotation({ item => nil, next_item => false })])).to be(false)
      expect(state.append_annotation_list([annotation({ item => false, next_item => nil })])).to be(false)
      expect(existing.contribution_matrix[actions.first]).to eq({ item => false, next_item => nil })
    end

    it "does not rescan incoming annotation keys for every existing annotation" do
      incoming = 8.times.map do |index|
        from = described_class.new(index + 1, token, [])
        state.annotation_list << annotation({ item => false }, from: from)
        annotation({ item => true }, from: from)
      end
      incoming.each { |entry| expect(entry).to receive(:state).at_most(2).times.and_call_original }

      state.append_annotation_list(incoming)

      expect(state.annotation_list.length).to eq(8)
      expect(state.annotation_list).to all(have_attributes(contribution_matrix: { actions.first => { item => true } }))
    end
  end
end
