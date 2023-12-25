RSpec.describe Lrama::Lexer::Location do
  describe "#to_s" do
    it "returns location information" do
      grammar_file = Lrama::Lexer::GrammarFile.new("test.y", "")
      location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
      expect(location.to_s).to eq "test.y (1,0)-(1,4)"
    end
  end

  describe "#partial_location" do
    it "creates new partial location" do
      path = fixture_path("lexer/location.y")
      grammar_file = Lrama::Lexer::GrammarFile.new(path, File.read(path))
      location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 38, first_column: 10, last_line: 42, last_column: 9)

      expect(location.partial_location(49, 57)).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 40, first_column: 11, last_line: 40, last_column: 19)
    end
  end

  describe "#generate_error_message" do
    it "returns decorated error message" do
      path = fixture_path("lexer/location.y")
      grammar_file = Lrama::Lexer::GrammarFile.new(path, File.read(path))
      location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 33, first_column: 12, last_line: 33, last_column: 15)
      expected = <<-TEXT
#{path}:33:12: ERROR
     | expr '+' expr { $$ = $1 + $3; }
            ^^^
      TEXT

      expect(location.generate_error_message("ERROR")).to eq expected
    end
  end

  describe "#line_with_carets" do
    it "returns line text with carets" do
      path = fixture_path("lexer/location.y")
      grammar_file = Lrama::Lexer::GrammarFile.new(path, File.read(path))
      location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 33, first_column: 12, last_line: 33, last_column: 15)
      expected = <<-TEXT
     | expr '+' expr { $$ = $1 + $3; }
            ^^^
      TEXT

      expect(location.line_with_carets).to eq expected
    end
  end
end
