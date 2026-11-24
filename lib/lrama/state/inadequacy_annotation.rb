# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    class InadequacyAnnotation
      # @rbs!
      #   type action = Action::Shift | Action::Reduce

      attr_accessor :state #: State
      attr_accessor :token #: Grammar::Symbol
      attr_accessor :actions #: Array[action]
      # Bit positions refer to the containing state's kernels, which may differ from @state's.
      attr_accessor :contribution_matrix #: Hash[action, Bitmap::bitmap?]

      # @rbs (State state, Grammar::Symbol token, Array[action] actions, Hash[action, Bitmap::bitmap?] contribution_matrix) -> void
      def initialize(state, token, actions, contribution_matrix)
        @state = state
        @token = token
        @actions = actions
        @contribution_matrix = contribution_matrix
      end

      # @rbs (Integer kernel_index) -> bool
      def contributed?(kernel_index)
        @contribution_matrix.any? {|action, contributions| !contributions.nil? && contributions[kernel_index] == 1 }
      end

      # Definition 3.42 (dominant_contribution)
      #
      # @rbs (State::lookahead_set lookaheads, Array[Item] kernels) -> Array[action]?
      def dominant_contribution(lookaheads, kernels)
        actions = @actions.select {|action|
          contributions = contribution_matrix[action]
          contributions.nil? || Bitmap.any?(contributions) {|index| lookaheads[kernels[index]][@token.number] == 1 }
        }
        return nil if actions.empty?

        resolve_conflict(actions)
      end

      # @rbs (Array[action] actions) -> Array[action]
      def resolve_conflict(actions)
        return actions if actions.length < 2

        shift = actions.find { |action| action.is_a?(Action::Shift) } #: Action::Shift?
        return actions unless shift
        shift_prec = shift.next_sym.precedence
        return actions unless shift_prec

        # @type var reduces: Array[Action::Reduce]
        reduces = actions.select { |action| action.is_a?(Action::Reduce) }
        # Match the order in which the parser tables resolve reductions against this shift.
        reduces.sort_by! { |reduce| reduce.rule.id } if reduces.length > 1

        reduces.each do |reduce|
          reduce_prec = reduce.rule.precedence
          next unless reduce_prec

          if shift_prec < reduce_prec
            actions.delete(shift)
            break
          elsif shift_prec > reduce_prec
            actions.delete(reduce)
            next
          end

          case shift_prec.type
          when :precedence
            # Equal precedence alone leaves the conflict unresolved.
            next
          when :right
            actions.delete(reduce)
          when :left
            actions.delete(shift)
            break
          when :nonassoc
            # An explicit syntax error overrides every remaining action for this token.
            # https://www.gnu.org/software/bison/manual/html_node/Using-Precedence.html
            return []
          else
            raise "Unknown precedence type. #{shift_prec.type}"
          end
        end

        actions
      end

      # @rbs () -> String
      def to_s
        "State: #{@state.id}, Token: #{@token.name}, Actions: #{actions_to_s}, Contributions: #{contribution_matrix_to_s}"
      end

      private

      # @rbs () -> String
      def actions_to_s
        '[' + @actions.map {|action|
          if action.is_a?(Action::Shift) || action.is_a?(Action::Goto)
            action.class.name
          elsif action.is_a?(Action::Reduce)
            "#{action.class.name}: (#{action.item})"
          end
        }.join(', ') + ']'
      end

      # @rbs () -> String
      def contribution_matrix_to_s
        '[' + @contribution_matrix.map {|action, contributions|
          "#{(action.is_a?(Action::Shift) || action.is_a?(Action::Goto)) ? action.class.name : "#{action.class.name}: (#{action.item})"}: #{contributions.nil? ? 'always' : Bitmap.to_array(contributions)}"
        }.join(', ') + ']'
      end
    end
  end
end
