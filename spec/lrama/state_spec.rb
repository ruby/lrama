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

  describe "#append_annotation_list" do
    it "matches state IDs and equal action arrays while retaining the existing annotation" do
      existing = annotation({ item => false, next_item => true })
      state.annotation_list << existing
      incoming = annotation({ item => true, next_item => false },
                            from: described_class.new(origin.id, token, []), with: actions.dup)
      propagating = [incoming]

      state.append_annotation_list(propagating)

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

      state.append_annotation_list(incoming)

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

    it "retains the current merge order and sharing of contribution hashes" do
      existing = annotation(nil)
      state.annotation_list << existing
      contributions = { item => false }

      state.append_annotation_list([annotation(contributions), annotation({ item => true }), annotation(nil)])

      expect(existing.contribution_matrix[actions.first]).to equal(contributions)
      expect(contributions).to eq({ item => true })
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
