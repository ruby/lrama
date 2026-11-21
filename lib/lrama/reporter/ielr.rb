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

        lalr_isocores = lalr_isocores_with_splits(states)
        return if lalr_isocores.empty?

        @incoming_transitions = build_incoming_transitions(states)
        token_names = states.terms.map { |term| [term.number, term.display_name] }.to_h

        io << "IELR Isocores\n\n"

        lalr_isocores.each do |lalr_isocore|
          report_isocore_set(io, lalr_isocore, token_names)
        end
      ensure
        @incoming_transitions = nil
      end

      private

      # @rbs (Lrama::States states) -> Array[Lrama::State]
      def lalr_isocores_with_splits(states)
        states.states.select do |state|
          !state.split_state? && state.ielr_isocores.size > 1
        end
      end

      # @rbs (Lrama::States states) -> Hash[Lrama::State, Array[Lrama::State::Action::Shift | Lrama::State::Action::Goto]]
      def build_incoming_transitions(states)
        incoming_transitions = Hash.new { |index, to_state| index[to_state] = [] } #: Hash[Lrama::State, Array[Lrama::State::Action::Shift | Lrama::State::Action::Goto]]
        states.states.each do |state|
          state.transitions.each do |transition|
            incoming_transitions[transition.to_state] << transition
          end
        end
        incoming_transitions
      end

      # @rbs (IO io, Lrama::State lalr_isocore, Hash[Integer, String] token_names) -> void
      def report_isocore_set(io, lalr_isocore, token_names)
        isocores = lalr_isocore.ielr_isocores.sort_by(&:id)

        io << "    Isocore of LALR state #{lalr_isocore.id}: IELR states #{isocores.map(&:id).join(', ')}\n\n"
        report_incoming_transitions(io, isocores)
        report_item_lookahead_differences(io, isocores, token_names)
        report_dominant_contributions(io, isocores)
        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] isocores) -> void
      def report_incoming_transitions(io, isocores)
        io << "      Incoming transitions\n"

        isocores.each do |isocore|
          @incoming_transitions[isocore]
            .sort_by { |transition| [transition.from_state.id, transition.next_sym.number] }
            .each do |transition|
              io << "        state #{transition.from_state.id} -- #{transition.next_sym.display_name} --> state #{isocore.id} #{isocore_label(isocore)}\n"
            end
        end

        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] isocores, Hash[Integer, String] token_names) -> void
      def report_item_lookahead_differences(io, isocores, token_names)
        differing_kernel_items = isocores.first.kernels.select do |kernel_item|
          isocores.map { |isocore| isocore.item_lookahead_set.fetch(kernel_item) }.uniq.size > 1
        end
        return if differing_kernel_items.empty?

        io << "      Lookahead differences\n"

        differing_kernel_items.each do |kernel_item|
          io << "        #{kernel_item.display_name}\n"

          isocores.each do |isocore|
            tokens = Bitmap.to_array(isocore.item_lookahead_set.fetch(kernel_item)).map { |number| token_names.fetch(number) }
            io << "          state #{isocore.id} #{isocore_label(isocore)}: [#{tokens.join(', ')}]\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Array[Lrama::State] isocores) -> void
      def report_dominant_contributions(io, isocores)
        lalr_isocore = isocores.first.lalr_isocore
        reported = false

        lalr_isocore.annotation_list.each do |annotation|
          dominant_contributions = isocores.map do |isocore|
            annotation.dominant_contribution(isocore.item_lookahead_set, isocore.kernels)
          end
          next if dominant_contributions.compact.uniq.size <= 1

          io << "      Why it split\n" unless reported
          reported = true
          io << "        token #{annotation.token.display_name} (conflict in LALR state #{annotation.state.id})\n"
          isocores.zip(dominant_contributions).each do |isocore, dominant_contribution|
            io << "          state #{isocore.id} #{isocore_label(isocore)}: #{format_dominant_contribution(dominant_contribution)}\n"
          end
        end

        io << "\n" if reported
      end

      # @rbs (Array[Lrama::State::InadequacyAnnotation::action]? dominant_contribution) -> String
      def format_dominant_contribution(dominant_contribution)
        return "no contribution" if dominant_contribution.nil?
        return "syntax error" if dominant_contribution.empty?

        dominant_contribution.map { |action| format_action(action) }.join(", ")
      end

      # @rbs (Lrama::State::InadequacyAnnotation::action action) -> String
      def format_action(action)
        case action
        when Lrama::State::Action::Shift
          "shift and go to state #{action.to_state.id}"
        when Lrama::State::Action::Reduce
          rule = action.item.rule
          "reduce using rule #{rule.id} (#{rule.lhs.display_name})"
        else
          raise "Unsupported action #{action.class}"
        end
      end

      # @rbs (Lrama::State isocore) -> String
      def isocore_label(isocore)
        isocore.split_state? ? "[IELR split]" : "[LALR core]"
      end
    end
  end
end
