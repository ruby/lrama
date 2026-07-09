# frozen_string_literal: true

RSpec.describe Lrama::Diagnostics::Reporter do
  let(:output) { StringIO.new }
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

  after do
    Lrama::Diagnostics::Color.enabled = false
  end

  describe '#initialize' do
    it 'creates a reporter with default options' do
      reporter = described_class.new(output: output)
      expect(reporter.error_count).to eq(0)
      expect(reporter.warning_count).to eq(0)
      expect(reporter.messages).to be_empty
    end

    it 'accepts color_mode option' do
      reporter = described_class.new(output: output, color_mode: :always)
      expect(reporter).to be_a(described_class)
    end
  end

  describe '#error' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'reports an error message' do
      reporter.error(location: location, message: 'unexpected token')

      expect(output.string).to include('error')
      expect(output.string).to include('unexpected token')
    end

    it 'increments error count' do
      reporter.error(location: location, message: 'test')
      expect(reporter.error_count).to eq(1)
    end

    it 'adds message to messages list' do
      reporter.error(location: location, message: 'test')
      expect(reporter.messages.size).to eq(1)
      expect(reporter.messages.first.type).to eq(:error)
    end

    it 'returns the created message' do
      result = reporter.error(location: location, message: 'test')
      expect(result).to be_a(Lrama::Diagnostics::Message)
      expect(result.type).to eq(:error)
    end
  end

  describe '#warning' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'reports a warning message' do
      reporter.warning(location: location, message: 'unused variable')

      expect(output.string).to include('warning')
      expect(output.string).to include('unused variable')
    end

    it 'increments warning count' do
      reporter.warning(location: location, message: 'test')
      expect(reporter.warning_count).to eq(1)
    end

    it 'adds message to messages list' do
      reporter.warning(location: location, message: 'test')
      expect(reporter.messages.size).to eq(1)
      expect(reporter.messages.first.type).to eq(:warning)
    end
  end

  describe '#note' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'creates a note message without reporting' do
      note = reporter.note(location: location, message: 'see definition here')

      expect(note).to be_a(Lrama::Diagnostics::Message)
      expect(note.type).to eq(:note)
      expect(output.string).to be_empty
      expect(reporter.messages).to be_empty
    end
  end

  describe '#errors?' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'returns false when no errors' do
      expect(reporter.errors?).to be false
    end

    it 'returns true when errors exist' do
      reporter.error(location: location, message: 'test')
      expect(reporter.errors?).to be true
    end
  end

  describe '#warnings?' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'returns false when no warnings' do
      expect(reporter.warnings?).to be false
    end

    it 'returns true when warnings exist' do
      reporter.warning(location: location, message: 'test')
      expect(reporter.warnings?).to be true
    end
  end

  describe '#any?' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'returns false when no messages' do
      expect(reporter.any?).to be false
    end

    it 'returns true when messages exist' do
      reporter.error(location: location, message: 'test')
      expect(reporter.any?).to be true
    end
  end

  describe '#summary' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'returns "no issues" when empty' do
      expect(reporter.summary).to eq('no issues')
    end

    it 'returns singular error count' do
      reporter.error(location: location, message: 'test')
      expect(reporter.summary).to eq('1 error')
    end

    it 'returns plural error count' do
      reporter.error(location: location, message: 'test1')
      reporter.error(location: location, message: 'test2')
      expect(reporter.summary).to eq('2 errors')
    end

    it 'returns singular warning count' do
      reporter.warning(location: location, message: 'test')
      expect(reporter.summary).to eq('1 warning')
    end

    it 'returns combined counts' do
      reporter.error(location: location, message: 'error1')
      reporter.error(location: location, message: 'error2')
      reporter.warning(location: location, message: 'warning1')
      expect(reporter.summary).to eq('2 errors, 1 warning')
    end
  end

  describe '#print_summary' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'does not print when no messages' do
      output.truncate(0)
      output.rewind
      reporter.print_summary
      expect(output.string).to be_empty
    end

    it 'prints summary when messages exist' do
      reporter.error(location: location, message: 'test')
      output.truncate(0)
      output.rewind
      reporter.print_summary
      expect(output.string).to include('1 error')
    end
  end

  describe '#reset' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'resets all counters and messages' do
      reporter.error(location: location, message: 'test')
      reporter.warning(location: location, message: 'test')

      reporter.reset

      expect(reporter.error_count).to eq(0)
      expect(reporter.warning_count).to eq(0)
      expect(reporter.messages).to be_empty
    end
  end

  describe '#sorted_messages' do
    let(:reporter) { described_class.new(output: output, color_mode: :never) }

    it 'returns messages sorted by severity' do
      reporter.warning(location: location, message: 'warning')
      reporter.error(location: location, message: 'error')

      sorted = reporter.sorted_messages

      expect(sorted.first.type).to eq(:error)
      expect(sorted.last.type).to eq(:warning)
    end
  end

  describe 'color output' do
    around do |example|
      original = ENV['NO_COLOR']
      ENV.delete('NO_COLOR')
      example.run
      ENV['NO_COLOR'] = original if original
    end

    it 'outputs colored text when color_mode is :always' do
      # Color.enabled must be set for colorize to work in Formatter
      Lrama::Diagnostics::Color.enabled = true
      reporter = described_class.new(output: output, color_mode: :always)
      reporter.error(location: location, message: 'test')

      expect(output.string).to include("\e[")
    end

    it 'outputs plain text when color_mode is :never' do
      Lrama::Diagnostics::Color.enabled = false
      reporter = described_class.new(output: output, color_mode: :never)
      reporter.error(location: location, message: 'test')

      expect(output.string).not_to include("\e[")
    end
  end
end
