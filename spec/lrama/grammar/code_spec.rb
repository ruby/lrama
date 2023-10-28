RSpec.describe Lrama::Grammar::Code do
  let(:token_class) { Lrama::Lexer::Token }
  let(:user_code_token) { token_class.new(type: token_class::User_code, s_value: "{ code 1 }") }
  let(:initial_act_token) { token_class.new(type: token_class::User_code, s_value: "%initial-action") }

  describe "#translated_code" do
    context "when the code type is :user_code" do
      it "calls #translated_user_code" do
        code = described_class.new(type: :user_code, token_code: user_code_token)

        expect(code).to receive(:translated_user_code)

        code.translated_code
      end
    end

    context "when the code type is :initial_action" do
      it "calls #translated_initial_action_code" do
        code = described_class.new(type: :initial_action, token_code: initial_act_token)

        expect(code).to receive(:translated_initial_action_code)

        code.translated_code
      end
    end
  end

  describe "#translated_printer_code" do
    let(:printer_token) { token_class.new(type: token_class::User_code, s_value: '<val>') }

    context "when the ref.value is '$' and ref.type is :dollar" do
      let(:reference) { Lrama::Grammar::Reference.new(value: '$', type: :dollar, first_column: 0, last_column: 4) }

      it "returns '((*yyvaluep).val)'" do
        code = described_class.new(type: :user_code, token_code: printer_token)
        references = double("references")
        allow(code).to receive(:references).and_return([reference])
        expect(code.translated_printer_code(printer_token)).to eq("((*yyvaluep).val)")
      end
    end

    context "when the ref.value is '$' and ref.type is :at" do
      let(:reference) { Lrama::Grammar::Reference.new(value: '$', type: :at, first_column: 0, last_column: 4) }

      it "returns '(*yylocationp)'" do
        code = described_class.new(type: :user_code, token_code: printer_token)
        references = double("references")
        allow(code).to receive(:references).and_return([reference])
        expect(code.translated_printer_code(printer_token)).to eq("(*yylocationp)")
      end
    end

    context "when the ref.value is 'n' and ref.type is :dollar" do
      let(:reference) { Lrama::Grammar::Reference.new(value: 'n', type: :dollar, first_column: 0, last_column: 4) }

      it "raises error" do
        code = described_class.new(type: :user_code, token_code: printer_token)
        references = double("references")
        allow(code).to receive(:references).and_return([reference])
        expect { code.translated_printer_code(printer_token) }.to raise_error("$n can not be used in %printer.")
      end
    end

    context "when the ref.value is 'n' and ref.type is :at" do
      let(:reference) { Lrama::Grammar::Reference.new(value: 'n', type: :at, first_column: 0, last_column: 4) }

      it "raises error" do
        code = described_class.new(type: :user_code, token_code: printer_token)
        references = double("references")
        allow(code).to receive(:references).and_return([reference])
        expect { code.translated_printer_code(printer_token) }.to raise_error("@n can not be used in %printer.")
      end
    end

    context "when unexpected ref.value and ref.type" do
      let(:reference) { Lrama::Grammar::Reference.new(value: 'invalid', type: :invalid, first_column: 0, last_column: 4) }

      it "raises error" do
        code = described_class.new(type: :user_code, token_code: printer_token)
        references = double("references")
        allow(code).to receive(:references).and_return([reference])
        expect { code.translated_printer_code(printer_token) }.to raise_error("Unexpected. #{code}, #{reference}")
      end
    end
  end
end
