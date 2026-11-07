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
