module Lrama
  class Grammar
    class ParserState
      attr_reader :state_id, :state_list

      def initialize(state_id:, state_list:)
        @state_id = state_id
        @state_list = state_list
      end

      def enum_definition
        <<~ENUM
          enum #{enum_name}
          {
            #{enum_body}
          };
          typedef enum #{enum_name} #{enum_type};

          static const char *const #{enum_name_table_name}[] = {
            #{int_to_name.join(", ")}
          };

          YY_ATTRIBUTE_UNUSED
          static const char *
          #{enum_name}_name (#{enum_type} num)
          {
            return #{enum_name_table_name}[num];
          }

          # define #{state_name_macro}(value) #{enum_name}_name (value)
          # define #{current_state_name_macro} #{state_name_macro} (*#{stack_prefix}_p)
        ENUM
      end

      def state_name_macro
        "YY_STATE_#{state_name.upcase}_NAME"
      end

      def current_state_name_macro
        "YY_CURRENT_STATE_#{state_name.upcase}_NAME"
      end

      def states_functions
        <<~FUNC
          # define YYPUSH_STATE_#{state_name.upcase}(value) \\
            do \\
              { \\
                if (#{stack_prefix} + #{states_stack_size_name} - 1 <= #{stack_prefix}_p) \\
                  YYSTATE_STACK_INCREASE (#{stack_prefix}_a, #{stack_prefix}, #{stack_prefix}_p, #{states_stack_size_name}, "#{state_name}"); \\
                YYDPRINTF ((stderr, "Push %s to #{state_name}\\n", #{state_name_macro} (value))); \\
                *++#{stack_prefix}_p = value; \\
              } \\
            while (0)

          # define YYPOP_STATE_#{state_name.upcase}() \\
            do \\
              { \\
                YYDPRINTF ((stderr, "Pop #{state_name}\\n")); \\
                if (#{stack_prefix}_p != #{stack_prefix}) \\
                  { \\
                    #{stack_prefix}_p -= 1; \\
                  } \\
                else \\
                  { \\
                    YYDPRINTF ((stderr, "Try to pop empty #{state_name} stack\\n")); \\
                  } \\
              } \\
            while (0)

          # define YYSET_STATE_#{state_name.upcase}(value) \\
            do \\
              { \\
                YYDPRINTF ((stderr, "Set %s to #{state_name}\\n", #{state_name_macro} (value))); \\
                *#{stack_prefix}_p = value; \\
              } \\
            while (0)

          # define YY_STATE_#{state_name.upcase} #{stack_prefix}_p
        FUNC
      end

      def states_clean_up_stack
        <<~CODE
          if (#{stack_prefix} != #{stack_prefix}_a)
            YYSTACK_FREE (#{stack_prefix});
        CODE
      end

      def states_stack_size_name
        "#{stack_prefix}_stacksize"
      end

      def states_stacks
        <<~STACKS
          /* Current size of state stack size */
          YYPTRDIFF_T #{states_stack_size_name} = YYINITDEPTH;

          /* The parser state stack (#{stack_prefix}): array, bottom, top.  */
          int #{stack_prefix}_a[YYINITDEPTH];
          int *#{stack_prefix} = #{stack_prefix}_a;
          int *#{stack_prefix}_p = #{stack_prefix};
        STACKS
      end

      def state_name
        state_id.s_value
      end

      def enum_name
        "yyparser_state_#{state_name}"
      end

      def enum_type
        "#{enum_name}_t"
      end

      def enum_body
        enum_numbers.join(",\n  ")
      end

      def int_to_name
        state_list.map do |state|
          "\"#{state.s_value}\""
        end << "YY_NULLPTR"
      end

      def enum_name_table_name
        "#{enum_name}_names"
      end

      def stack_prefix
        "yyparser_state_#{state_name}"
      end

      private

      def enum_numbers
        state_list.map do |state|
          "yyparser_state_#{state.s_value}"
        end
      end
    end
  end
end
