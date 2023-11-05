RSpec.describe Lrama::Grammar::Code do
  let(:token_class) { Lrama::Lexer::Token }
  let(:user_code_token) { token_class::UserCode.new(s_value: "{ code 1 }") }
  let(:initial_act_token) { token_class::UserCode.new(s_value: "%initial-action") }

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
    let(:tag) { token_class::Tag.new(s_value: '<val>') }

    context "when the ref.value is '$' and ref.type is :dollar" do
      let(:user_code) { token_class::UserCode.new(s_value: 'print($$);') }

      it "returns '((*yyvaluep).val)'" do
        code = described_class.new(type: :user_code, token_code: user_code)
        expect(code.translated_printer_code(tag)).to eq("print(((*yyvaluep).val));")
      end
    end

    context "when the ref.value is '$' and ref.type is :at" do
      let(:user_code) { token_class::UserCode.new(s_value: 'print(@$);') }

      it "returns '(*yylocationp)'" do
        code = described_class.new(type: :user_code, token_code: user_code)
        expect(code.translated_printer_code(tag)).to eq("print((*yylocationp));")
      end
    end

    context "when the ref.value is 'n' and ref.type is :dollar" do
      let(:user_code) { token_class::UserCode.new(s_value: 'print($n);') }

      it "raises error" do
        code = described_class.new(type: :user_code, token_code: user_code)
        expect { code.translated_printer_code(tag) }.to raise_error("$n can not be used in %printer.")
      end
    end

    context "when the ref.value is 'n' and ref.type is :at" do
      let(:user_code) { token_class::UserCode.new(s_value: 'print(@n);') }

      it "raises error" do
        code = described_class.new(type: :user_code, token_code: user_code)
        expect { code.translated_printer_code(tag) }.to raise_error("@n can not be used in %printer.")
      end
    end
  end
end
