# TODO: spec for Lrama::Grammar::Code::RuleAction

RSpec.describe Lrama::Grammar::Code do
  let(:token_class) { Lrama::Lexer::Token }
  let(:user_code_dollar_dollar) { token_class::UserCode.new(s_value: 'print($$);') }
  let(:user_code_at_dollar) { token_class::UserCode.new(s_value: 'print(@$);') }
  let(:user_code_dollar_n) { token_class::UserCode.new(s_value: 'print($n);') }
  let(:user_code_at_n) { token_class::UserCode.new(s_value: 'print(@n);') }

  describe Lrama::Grammar::Code::InitialActionCode do
    describe "#translated_code" do
      it "translats '$$' to 'yylval'" do
        code = described_class.new(type: :initial_action, token_code: user_code_dollar_dollar)
        expect(code.translated_code).to eq("print(yylval);")
      end

      it "translats '@$' to 'yylloc'" do
        code = described_class.new(type: :initial_action, token_code: user_code_at_dollar)
        expect(code.translated_code).to eq("print(yylloc);")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :initial_action, token_code: user_code_dollar_n)
        expect { code.translated_code }.to raise_error("$n can not be used in initial_action.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :initial_action, token_code: user_code_at_n)
        expect { code.translated_code }.to raise_error("@n can not be used in initial_action.")
      end
    end
  end

  describe Lrama::Grammar::Code::NoReferenceCode do
    describe "#translated_code" do
      it "raises error for '$$'" do
        code = described_class.new(type: :union, token_code: user_code_dollar_dollar)
        expect { code.translated_code }.to raise_error("$$ can not be used in union.")
      end

      it "raises error for '@$'" do
        code = described_class.new(type: :union, token_code: user_code_at_dollar)
        expect { code.translated_code }.to raise_error("@$ can not be used in union.")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :union, token_code: user_code_dollar_n)
        expect { code.translated_code }.to raise_error("$n can not be used in union.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :union, token_code: user_code_at_n)
        expect { code.translated_code }.to raise_error("@n can not be used in union.")
      end
    end
  end

  describe Lrama::Grammar::Code::PrinterCode do
    describe "#translated_code" do
      let(:tag) { token_class::Tag.new(s_value: '<val>') }

      it "translats '$$' to '((*yyvaluep).val)'" do
        code = described_class.new(type: :printer, token_code: user_code_dollar_dollar)
        code.tag = tag
        expect(code.translated_code).to eq("print(((*yyvaluep).val));")
      end

      it "translats '@$' to '(*yylocationp)'" do
        code = described_class.new(type: :printer, token_code: user_code_at_dollar)
        code.tag = tag
        expect(code.translated_code).to eq("print((*yylocationp));")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :printer, token_code: user_code_dollar_n)
        code.tag = tag
        expect { code.translated_code }.to raise_error("$n can not be used in printer.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :printer, token_code: user_code_at_n)
        code.tag = tag
        expect { code.translated_code }.to raise_error("@n can not be used in printer.")
      end
    end
  end
end
