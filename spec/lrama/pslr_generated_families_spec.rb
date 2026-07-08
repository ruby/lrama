# frozen_string_literal: true

RSpec.describe "PSLR generated family coverage" do
  include PslrFamilyHelper

  families = [
    {
      label: "keyword/id",
      builder: :keyword_context_source,
      path_prefix: "generated/pslr_keyword_depth",
      split_expected: true
    },
    {
      label: "shift/angle",
      builder: :shift_angle_source,
      path_prefix: "generated/pslr_shift_depth",
      split_expected: true
    },
    {
      label: "mixed",
      builder: :mixed_context_source,
      path_prefix: "generated/pslr_mixed_depth",
      split_expected: true
    }
  ].freeze

  families.each do |family|
    (0..3).each do |depth|
      it "#{family[:label]} depth=#{depth} keeps PSLR inadequacies resolved" do
        grammar = build_grammar(
          public_send(family[:builder], depth: depth),
          "#{family[:path_prefix]}_#{depth}.y"
        )
        ielr_states, pslr_states = compute_ielr_and_pslr(grammar)

        aggregate_failures do
          expect(pslr_states.pslr_inadequacies).to be_empty
          expect(pslr_states.states_count).to be >= ielr_states.states_count
          expect(pslr_states.pslr_metrics[:growth_count]).to eq(pslr_states.states_count - pslr_states.pslr_metrics[:base_states_count])

          next unless family[:split_expected]
          next unless 1 <= depth

          expect(pslr_states.states_count).to be > ielr_states.states_count
        end
      end
    end
  end
end
