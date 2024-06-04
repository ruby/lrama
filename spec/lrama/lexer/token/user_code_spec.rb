# frozen_string_literal: true

RSpec.describe Lrama::Lexer::Token::UserCode do
  describe "#references" do
    let(:grammar_file) { Lrama::Lexer::GrammarFile.new("test.y", "") }
    let(:location) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 2) }

    it "returns references in user code" do
      # $$
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $$ ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "$", ex_tag: nil, first_column: 1, last_column: 3)
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $<long>$ ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "$", ex_tag: Lrama::Lexer::Token::Tag.new(s_value: "<long>"), first_column: 1, last_column: 9)

      # $1
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $1 ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, number: 1, index: 1, ex_tag: nil, first_column: 1, last_column: 3)
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $<long>1 ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, number: 1, index: 1, ex_tag: Lrama::Lexer::Token::Tag.new(s_value: "<long>"), first_column: 1, last_column: 9)

      # $foo
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $foo ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "foo", ex_tag: nil, first_column: 1, last_column: 5)
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $<long>foo ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "foo", ex_tag: Lrama::Lexer::Token::Tag.new(s_value: "<long>"), first_column: 1, last_column: 11)

      # $[expr.right]
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $[expr.right] ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "expr.right", ex_tag: nil, first_column: 1, last_column: 14)
      references = Lrama::Lexer::Token::UserCode.new(s_value: " $<long>[expr.right] ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :dollar, name: "expr.right", ex_tag: Lrama::Lexer::Token::Tag.new(s_value: "<long>"), first_column: 1, last_column: 20)

      # @$
      references = Lrama::Lexer::Token::UserCode.new(s_value: " @$ ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :at, name: "$", ex_tag: nil, first_column: 1, last_column: 3)

      # @1
      references = Lrama::Lexer::Token::UserCode.new(s_value: " @1 ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :at, number: 1, index: 1, ex_tag: nil, first_column: 1, last_column: 3)

      # @foo
      references = Lrama::Lexer::Token::UserCode.new(s_value: " @foo ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :at, name: "foo", ex_tag: nil, first_column: 1, last_column: 5)

      # @[expr.right]
      references = Lrama::Lexer::Token::UserCode.new(s_value: " @[expr.right] ", location: location).references
      expect(references.count).to eq 1
      expect(references[0]).to eq Lrama::Grammar::Reference.new(type: :at, name: "expr.right", ex_tag: nil, first_column: 1, last_column: 14)
    end
  end
end
