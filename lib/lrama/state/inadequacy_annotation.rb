module Lrama
  class State
    class InadequacyAnnotation
      attr_accessor :state, :token, :actions, :contribution_matrix

      def initialize(state, token, actions, contribution_matrix)
        @state = state
        @token = token
        @actions = Set.new(actions)
        @contribution_matrix = contribution_matrix
      end

      def eql?(other)
        %i(state token actions contribution_matrix).all? {|attr| send(attr) == other.send(attr) }
      end

      def hash
        to_s.hash
      end

      def mergeable?(other)
        @state == other.state && @token == other.token
      end

      def merge(other)
        @actions += other.actions
      end

      def contributed?(item)
        @contribution_matrix.any? {|action, contributions| !contributions.nil? && contributions[item] }
      end

      def merge_matrix(another_matrix)
        @contribution_matrix.merge(another_matrix) {|action, contributions, another_contributions|
          next contributions if another_contributions.nil?
          next another_contributions if contributions.nil?

          contributions.merge(another_contributions) {|_, contributed, another_contributed| contributed || another_contributed }
        }
      end

      # Definition 3.42 (dominant_contribution)
      def dominant_contribution(lookaheads)
        actions = @actions.select {|action|
          contribution_matrix[action].nil? || contribution_matrix[action].any? {|item, contributed| contributed && lookaheads[item].include?(@token) }
        }
        return nil if actions.empty?

        # @type var shifts: Array[Shift]
        # @type var reduces: Array[Reduce]
        shifts, reduces = actions.partition {|action| action.is_a?(Shift) }

        shifts.each do |shift|
          reduces.each do |reduce|
            sym = shift.next_sym

            shift_prec = sym.precedence
            reduce_prec = reduce.item.rule.precedence

            # Can resolve only when both have prec
            unless shift_prec && reduce_prec
              next
            end

            case
            when shift_prec < reduce_prec
              # Reduce is selected
              actions.delete(shift)
              next
            when shift_prec > reduce_prec
              # Shift is selected
              actions.delete(reduce)
              next
            end

            # shift_prec == reduce_prec, then check associativity
            case sym.precedence&.type
            when :precedence
              # %precedence only specifies precedence and not specify associativity
              # then a conflict is unresolved if precedence is same.
              next
            when :right
              # Shift is selected
              actions.delete(reduce)
              next
            when :left
              # Reduce is selected
              actions.delete(shift)
              next
            when :nonassoc
              # Can not resolve
              #
              # nonassoc creates "run-time" error, precedence creates "compile-time" error.
              # Then omit both the shift and reduce.
              #
              # https://www.gnu.org/software/bison/manual/html_node/Using-Precedence.html
              actions.delete(shift)
              actions.delete(reduce)
            else
              raise "Unknown precedence type. #{sym}"
            end
          end
        end

        actions
      end

      def to_s
        "State: #{@state.id}, Token: #{@token.id.s_value}, Actions: #{actions_to_s}, Contributions: #{contribution_matrix_to_s}"
      end

      def actions_to_s
        '[' + @actions.map {|action|
          if action.is_a?(Shift)
            action.class.name
          elsif action.is_a?(Reduce)
            "#{action.class.name}: (#{action.item.to_s})"
          end
        }.join(', ') + ']'
      end

      def contribution_matrix_to_s
        '[' + @contribution_matrix.map {|action, contributions|
          "#{action.is_a?(Shift) ? action.class.name : "#{action.class.name}: (#{action.item.to_s})"}: " + contributions&.transform_keys(&:to_s).to_s
        }.join(', ') + ']'
      end
    end
  end
end
