# frozen_string_literal: true

RSpec.describe Lrama::Diagnostics::Message do
  let(:location) do
    double(
      'Location',
      path: 'test.y',
      filename: 'test.y',
      first_line: 10,
      first_column: 5,
      last_line: 10,
      last_column: 15
    )
  end

  describe '#initialize' do
    it 'creates a message with required attributes' do
      message = described_class.new(
        type: :error,
        location: location,
        message: 'unexpected token'
      )

      expect(message.type).to eq(:error)
      expect(message.location).to eq(location)
      expect(message.message).to eq('unexpected token')
    end

    it 'creates a message with optional attributes' do
      note = described_class.new(type: :note, location: nil, message: 'note')
      message = described_class.new(
        type: :warning,
        location: location,
        message: 'unused variable',
        source_line: '%token FOO',
        notes: [note],
        fixit: 'remove this'
      )

      expect(message.source_line).to eq('%token FOO')
      expect(message.notes).to eq([note])
      expect(message.fixit).to eq('remove this')
    end
  end

  describe '#severity' do
    it 'returns 3 for error' do
      message = described_class.new(type: :error, location: nil, message: 'test')
      expect(message.severity).to eq(3)
    end

    it 'returns 2 for warning' do
      message = described_class.new(type: :warning, location: nil, message: 'test')
      expect(message.severity).to eq(2)
    end

    it 'returns 1 for note' do
      message = described_class.new(type: :note, location: nil, message: 'test')
      expect(message.severity).to eq(1)
    end

    it 'returns 0 for unknown type' do
      message = described_class.new(type: :unknown, location: nil, message: 'test')
      expect(message.severity).to eq(0)
    end
  end

  describe 'type predicates' do
    it '#error? returns true for error type' do
      message = described_class.new(type: :error, location: nil, message: 'test')
      expect(message.error?).to be true
      expect(message.warning?).to be false
      expect(message.note?).to be false
    end

    it '#warning? returns true for warning type' do
      message = described_class.new(type: :warning, location: nil, message: 'test')
      expect(message.error?).to be false
      expect(message.warning?).to be true
      expect(message.note?).to be false
    end

    it '#note? returns true for note type' do
      message = described_class.new(type: :note, location: nil, message: 'test')
      expect(message.error?).to be false
      expect(message.warning?).to be false
      expect(message.note?).to be true
    end
  end

  describe 'location accessors' do
    it 'returns file from location.path' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.file).to eq('test.y')
    end

    it 'returns nil when location is nil' do
      message = described_class.new(type: :error, location: nil, message: 'test')
      expect(message.file).to be_nil
      expect(message.line).to be_nil
      expect(message.column).to be_nil
    end

    it 'returns line numbers from location' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.line).to eq(10)
      expect(message.end_line).to eq(10)
    end

    it 'returns column numbers from location' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.column).to eq(5)
      expect(message.end_column).to eq(15)
    end
  end

  describe '#location?' do
    it 'returns true when location is present' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.location?).to be true
    end

    it 'returns false when location is nil' do
      message = described_class.new(type: :error, location: nil, message: 'test')
      expect(message.location?).to be false
    end
  end

  describe '#source_line?' do
    it 'returns true when source_line is present and not empty' do
      message = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        source_line: 'some code'
      )
      expect(message.source_line?).to be true
    end

    it 'returns false when source_line is nil' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.source_line?).to be false
    end

    it 'returns false when source_line is empty' do
      message = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        source_line: ''
      )
      expect(message.source_line?).to be false
    end
  end

  describe '#notes?' do
    it 'returns true when notes are present' do
      note = described_class.new(type: :note, location: nil, message: 'note')
      message = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        notes: [note]
      )
      expect(message.notes?).to be true
    end

    it 'returns false when notes is empty' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.notes?).to be false
    end
  end

  describe '#fixit?' do
    it 'returns true when fixit is present' do
      message = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        fixit: 'fix this'
      )
      expect(message.fixit?).to be true
    end

    it 'returns false when fixit is nil' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.fixit?).to be false
    end

    it 'returns false when fixit is empty' do
      message = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        fixit: ''
      )
      expect(message.fixit?).to be false
    end
  end

  describe '#range_length' do
    it 'returns the length of the range' do
      message = described_class.new(type: :error, location: location, message: 'test')
      expect(message.range_length).to eq(10)
    end

    it 'returns 1 when location is nil' do
      message = described_class.new(type: :error, location: nil, message: 'test')
      expect(message.range_length).to eq(1)
    end

    it 'returns at least 1' do
      loc = double(
        'Location',
        path: 'test.y',
        first_line: 1,
        first_column: 5,
        last_line: 1,
        last_column: 5
      )
      message = described_class.new(type: :error, location: loc, message: 'test')
      expect(message.range_length).to eq(1)
    end
  end

  describe '#<=>' do
    let(:error1) do
      described_class.new(
        type: :error,
        location: double(path: 'a.y', first_line: 1, first_column: 1, last_line: 1, last_column: 1),
        message: 'error 1'
      )
    end

    let(:error2) do
      described_class.new(
        type: :error,
        location: double(path: 'a.y', first_line: 2, first_column: 1, last_line: 2, last_column: 1),
        message: 'error 2'
      )
    end

    let(:warning) do
      described_class.new(
        type: :warning,
        location: double(path: 'a.y', first_line: 1, first_column: 1, last_line: 1, last_column: 1),
        message: 'warning'
      )
    end

    it 'sorts by severity first (errors before warnings)' do
      expect(error1 <=> warning).to eq(-1)
    end

    it 'sorts by line number for same severity' do
      expect(error1 <=> error2).to eq(-1)
    end

    it 'returns nil when comparing with non-Message' do
      expect(error1 <=> 'string').to be_nil
    end
  end

  describe '#to_s' do
    it 'formats message with location' do
      message = described_class.new(type: :error, location: location, message: 'unexpected token')
      expect(message.to_s).to eq('test.y:10:5: error: unexpected token')
    end

    it 'formats message without location' do
      message = described_class.new(type: :error, location: nil, message: 'unexpected token')
      expect(message.to_s).to eq('error: unexpected token')
    end
  end

  describe '#add_note' do
    it 'adds a note to the message' do
      message = described_class.new(type: :error, location: location, message: 'test')
      note = described_class.new(type: :note, location: nil, message: 'note')

      result = message.add_note(note)

      expect(result).to eq(message)
      expect(message.notes).to include(note)
    end
  end

  describe '#dup' do
    it 'creates a copy of the message' do
      original = described_class.new(
        type: :error,
        location: location,
        message: 'test',
        source_line: 'code',
        fixit: 'fix'
      )

      copy = original.dup

      expect(copy.type).to eq(original.type)
      expect(copy.location).to eq(original.location)
      expect(copy.message).to eq(original.message)
      expect(copy.source_line).to eq(original.source_line)
      expect(copy.fixit).to eq(original.fixit)
      expect(copy).not_to equal(original)
    end
  end
end
