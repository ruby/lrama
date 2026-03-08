# frozen_string_literal: true

RSpec.describe Lrama::Lexer::Token::Regex do
  describe "#pattern" do
    it "returns the pattern without surrounding slashes" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>>/")
      expect(regex.pattern).to eq(">>>")
    end

    it "handles character class patterns" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[a-zA-Z_][a-zA-Z0-9_]*/")
      expect(regex.pattern).to eq("[a-zA-Z_][a-zA-Z0-9_]*")
    end

    it "handles escape sequences" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/\\+/")
      expect(regex.pattern).to eq("\\+")
    end

    it "handles empty pattern" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "//")
      expect(regex.pattern).to eq("")
    end

    it "handles single character pattern" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
      expect(regex.pattern).to eq(">")
    end
  end

  describe "#s_value" do
    it "returns the original value including slashes" do
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>>/")
      expect(regex.s_value).to eq("/>>>/")
    end
  end
end
