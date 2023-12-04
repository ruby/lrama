RSpec.describe Lrama::Grammar::ParserState do
  let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 0) }
  let(:state_id) { Lrama::Lexer::Token::Ident.new(s_value: "in_rescue", location: location) }
  let(:state_list) do
    [
      Lrama::Lexer::Token::Ident.new(s_value: "before_rescue", location: location),
      Lrama::Lexer::Token::Ident.new(s_value: "after_rescue", location: location),
      Lrama::Lexer::Token::Ident.new(s_value: "after_else", location: location),
      Lrama::Lexer::Token::Ident.new(s_value: "after_ensure", location: location)
    ]
  end
  let(:parser_state) { Lrama::Grammar::ParserState.new(state_id: state_id, state_list: state_list) }

  describe "#enum_definition" do
    it "returns enum definition" do
      expect(parser_state.enum_definition).to eq <<~ENUM
        enum yyparser_state_in_rescue
        {
          yyparser_state_before_rescue,
          yyparser_state_after_rescue,
          yyparser_state_after_else,
          yyparser_state_after_ensure
        };
        typedef enum yyparser_state_in_rescue yyparser_state_in_rescue_t;

        static const char *const yyparser_state_in_rescue_names[] = {
          "before_rescue", "after_rescue", "after_else", "after_ensure", YY_NULLPTR
        };

        YY_ATTRIBUTE_UNUSED
        static const char *
        yyparser_state_in_rescue_name (yyparser_state_in_rescue_t num)
        {
          return yyparser_state_in_rescue_names[num];
        }

        # define YY_STATE_IN_RESCUE_NAME(value) yyparser_state_in_rescue_name (value)
        # define YY_CURRENT_STATE_IN_RESCUE_NAME YY_STATE_IN_RESCUE_NAME (*yyparser_state_in_rescue_p)
      ENUM
    end
  end

  describe "#state_name_macro" do
    it "returns name of state name macro" do
      expect(parser_state.state_name_macro).to eq "YY_STATE_IN_RESCUE_NAME"
    end
  end

  describe "#current_state_name_macro" do
    it "returns name of current state name macro" do
      expect(parser_state.current_state_name_macro).to eq "YY_CURRENT_STATE_IN_RESCUE_NAME"
    end
  end

  describe "#states_functions" do
    it "returns states functions" do
      expect(parser_state.states_functions).to eq <<~FUNC
        # define YYPUSH_STATE_IN_RESCUE(value) \\
          do \\
            { \\
              if (yyparser_state_in_rescue_b + yyparser_state_in_rescue_stacksize - 1 <= yyparser_state_in_rescue_p) \\
                YYSTATE_STACK_INCREASE (yyparser_state_in_rescue_a, yyparser_state_in_rescue_b, yyparser_state_in_rescue_p, yyparser_state_in_rescue_stacksize, "in_rescue"); \\
              YYDPRINTF ((stderr, "Push %s to in_rescue\\n", YY_STATE_IN_RESCUE_NAME (yyparser_state_ ## value))); \\
              *++yyparser_state_in_rescue_p = yyparser_state_ ## value; \\
            } \\
          while (0)

        # define YYPOP_STATE_IN_RESCUE() \\
          do \\
            { \\
              YYDPRINTF ((stderr, "Pop in_rescue\\n")); \\
              if (yyparser_state_in_rescue_p != yyparser_state_in_rescue_b) \\
                { \\
                  yyparser_state_in_rescue_p -= 1; \\
                } \\
              else \\
                { \\
                  YYDPRINTF ((stderr, "Try to pop empty in_rescue stack\\n")); \\
                } \\
            } \\
          while (0)

        # define YYSET_STATE_IN_RESCUE(value) \\
          do \\
            { \\
              YYDPRINTF ((stderr, "Set %s to in_rescue\\n", YY_STATE_IN_RESCUE_NAME (yyparser_state_ ## value))); \\
              *yyparser_state_in_rescue_p = yyparser_state_ ## value; \\
            } \\
          while (0)

        # define YY_STATE_IN_RESCUE yyparser_state_in_rescue_p
      FUNC
    end
  end

  describe "#states_clean_up_stack" do
    it "returns states clean up codes" do
      expect(parser_state.states_clean_up_stack).to eq <<~CODE
        if (yyparser_state_in_rescue_b != yyparser_state_in_rescue_a)
          YYSTACK_FREE (yyparser_state_in_rescue_b);
      CODE
    end
  end

  describe "#states_stack_size_name" do
    it "returns states stack size name" do
      expect(parser_state.states_stack_size_name).to eq "yyparser_state_in_rescue_stacksize"
    end
  end

  describe "#states_stacks" do
    it "returns states stacks" do
      expect(parser_state.states_stacks).to eq <<~STACKS
        /* Current size of state stack size */
        YYPTRDIFF_T yyparser_state_in_rescue_stacksize = YYINITDEPTH;

        /* The parser state stack (yyparser_state_in_rescue): array, bottom, top.  */
        int yyparser_state_in_rescue_a[YYINITDEPTH];
        int *yyparser_state_in_rescue_b = yyparser_state_in_rescue_a;
        int *yyparser_state_in_rescue_p = yyparser_state_in_rescue_b;
      STACKS
    end
  end

  describe "#state_name" do
    it "returns state name" do
      expect(parser_state.state_name).to eq "in_rescue"
    end
  end

  describe "#enum_name" do
    it "returns enum name" do
      expect(parser_state.enum_name).to eq "yyparser_state_in_rescue"
    end
  end

  describe "#enum_type" do
    it "returns enum type" do
      expect(parser_state.enum_type).to eq "yyparser_state_in_rescue_t"
    end
  end

  describe "#enum_body" do
    it "returns enum body" do
      expect(parser_state.enum_body).to eq <<~BODY.chomp
        yyparser_state_before_rescue,
          yyparser_state_after_rescue,
          yyparser_state_after_else,
          yyparser_state_after_ensure
      BODY
    end
  end

  describe "#int_to_name" do
    it "returns int to name table" do
      expect(parser_state.int_to_name).to eq [
        "\"before_rescue\"",
        "\"after_rescue\"",
        "\"after_else\"",
        "\"after_ensure\"",
        "YY_NULLPTR"
      ]
    end
  end

  describe "#enum_name_table_name" do
    it "returns table name" do
      expect(parser_state.enum_name_table_name).to eq "yyparser_state_in_rescue_names"
    end
  end

  describe "#stack_prefix" do
    it "returns prefix" do
      expect(parser_state.stack_prefix).to eq "yyparser_state_in_rescue"
    end
  end
end
