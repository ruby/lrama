RSpec.describe Lrama::Lexer::Location do
  describe "#to_s" do
    it "returns location information" do
      location = Lrama::Lexer::Location.new(grammar_file_path: "test.y", first_line: 1, first_column: 0, last_line: 1, last_column: 4)
      expect(location.to_s).to eq "test.y (1,0)-(1,4)"
    end
  end

  describe "#generate_error_message" do
    it "returns decorated error message" do
      path = fixture_path("lexer/location.y")
      location = Lrama::Lexer::Location.new(grammar_file_path: path, first_line: 33, first_column: 12, last_line: 33, last_column: 15)
      expected = <<-TEXT
#{path}:33:12: ERROR
     | expr '+' expr { $$ = $1 + $3; }
            ^^^
      TEXT

      expect(location.generate_error_message("ERROR")).to eq expected
    end
  end

  describe "#line_with_carrets" do
    it "returns line text with carrets" do
      path = fixture_path("lexer/location.y")
      location = Lrama::Lexer::Location.new(grammar_file_path: path, first_line: 33, first_column: 12, last_line: 33, last_column: 15)
      expected = <<-TEXT
     | expr '+' expr { $$ = $1 + $3; }
            ^^^
      TEXT

      expect(location.line_with_carrets).to eq expected
    end
  end
end
