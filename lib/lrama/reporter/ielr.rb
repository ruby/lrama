# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    class Ielr
      # @rbs (?ielr: bool, **bool _) -> void
      def initialize(ielr: false, **_)
        @enabled = ielr
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report(io, states)
        return unless @enabled && states.ielr_defined?

        groups = split_groups(states)
        return if groups.empty?

        @incoming_index = build_incoming_index(states)

        io << "IELR State Splits\n\n"

        groups.each do |core|
          report_group(io, core)
        end
      ensure
        @incoming_index = nil
      end

      private

      # @rbs (Lrama::States states) -> Array[Lrama::State]
      def split_groups(states)
        states.states.select do |state|
          !state.split_state? && state.ielr_isocores.size > 1
        end
      end

      # @rbs (Lrama::States states) -> Hash[Lrama::State, Array[Lrama::State::Action::Shift | Lrama::State::Action::Goto]]
      def build_incoming_index(states)
        index = Hash.new { |h, k| h[k] = [] } #: Hash[Lrama::State, Array[Lrama::State::Action::Shift | Lrama::State::Action::Goto]]
        states.states.each do |state|
          state.transitions.each do |transition|
            index[transition.to_state] << transition
          end
        end
        index
      end

      # @rbs (IO io, Lrama::State core) -> void
      def report_group(io, core)
        variants = core.ielr_isocores.sort_by(&:id)

        io << "    LALR state #{core.id} splits into IELR states #{variants.map(&:id).join(', ')}\n\n"
        report_incoming_transitions(io, variants)
        report_lookahead_differences(io, variants)
        report_split_reasons(io, variants)
        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] variants) -> void
      def report_incoming_transitions(io, variants)
        io << "      Incoming transitions\n"

        variants.each do |variant|
          @incoming_index[variant]
            .sort_by { |t| [t.from_state.id, t.next_sym.number] }
            .each do |transition|
              io << "        state #{transition.from_state.id} -- #{transition.next_sym.display_name} --> state #{variant.id} #{state_role(variant)}\n"
            end
        end

        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] variants) -> void
      def report_lookahead_differences(io, variants)
        differing_items = variants.first.kernels.select do |item|
          variants.map { |state| lookahead_signature(state.item_lookahead_set[item]) }.uniq.size > 1
        end
        return if differing_items.empty?

        io << "      Lookahead differences\n"

        differing_items.each do |item|
          io << "        #{item.display_name}\n"

          variants.each do |state|
            io << "          state #{state.id} #{state_role(state)}: #{format_lookaheads(state.item_lookahead_set[item])}\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] variants) -> void
      def report_split_reasons(io, variants)
        core = variants.first.lalr_isocore
        different_annotations = [] #: Array[[Lrama::State::InadequacyAnnotation, Hash[Lrama::State, String]]]

        core.annotation_list.each do |annotation|
          labels_by_state = variants.map do |state|
            [state, dominant_actions(state, annotation)]
          end.to_h
          next if labels_by_state.values.uniq.size <= 1

          different_annotations << [annotation, labels_by_state]
        end
        return if different_annotations.empty?

        io << "      Why it split\n"

        different_annotations.each do |annotation, labels_by_state|
          io << "        token #{annotation.token.display_name}\n"

          variants.each do |state|
            io << "          state #{state.id} #{state_role(state)}: #{labels_by_state[state]}\n"
          end
        end

        io << "\n"
      end

      # @rbs (Array[Lrama::Grammar::Symbol] syms) -> Array[Integer]
      def lookahead_signature(syms)
        syms.map(&:number).sort
      end

      # @rbs (Array[Lrama::Grammar::Symbol] syms) -> String
      def format_lookaheads(syms)
        values = syms.sort_by(&:number).map(&:display_name)
        "[#{values.join(', ')}]"
      end

      # @rbs (Lrama::State state, Lrama::State::InadequacyAnnotation annotation) -> String
      def dominant_actions(state, annotation)
        actions = annotation.dominant_contribution(state.item_lookahead_set)
        return "no dominant action" if actions.nil? || actions.empty?

        actions.map { |action| format_action(state, action) }.join(", ")
      end

      # @rbs (Lrama::State state, Lrama::State::Action::Shift | Lrama::State::Action::Reduce action) -> String
      def format_action(state, action)
        case action
        when Lrama::State::Action::Shift
          current_shift = state.term_transitions.find { |shift| shift.next_sym == action.next_sym }
          destination = current_shift ? current_shift.to_state.id : action.to_state.id
          "shift and go to state #{destination}"
        when Lrama::State::Action::Reduce
          rule = action.item.rule
          "reduce using rule #{rule.id} (#{rule.lhs.display_name})"
        else
          raise "Unsupported action #{action.class}"
        end
      end

      # @rbs (Lrama::State state) -> String
      def state_role(state)
        state.split_state? ? "[IELR split]" : "[LALR core]"
      end
    end
  end
end
