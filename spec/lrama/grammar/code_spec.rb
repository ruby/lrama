RSpec.describe Lrama::Grammar::Code do
  let(:token_class) { Lrama::Lexer::Token }
  let(:user_code_token) { token_class.new(type: token_class::User_code, s_value: "{ code 1 }") }
  let(:initial_act_token) { token_class.new(type: token_class::P_initial_action, s_value: "%initial-action") }

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
end
