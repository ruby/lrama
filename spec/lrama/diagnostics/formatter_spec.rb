# frozen_string_literal: true

RSpec.describe Lrama::Diagnostics::Formatter do
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
    it 'creates a formatter with default options' do
      formatter = described_class.new
      expect(formatter).to be_a(described_class)
    end

    it 'accepts color_enabled option' do
      formatter = described_class.new(color_enabled: true)
      expect(formatter).to be_a(described_class)
    end
  end

  describe '#format' do
    let(:formatter) { described_class.new(color_enabled: false) }

    context 'with basic message' do
      it 'formats error message with location' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: 'unexpected token'
        )

        result = formatter.format(message)

        expect(result).to include('test.y:10')
        expect(result).to include('error')
        expect(result).to include('unexpected token')
      end

      it 'formats warning message' do
        message = Lrama::Diagnostics::Message.new(
          type: :warning,
          location: location,
          message: 'unused variable'
        )

        result = formatter.format(message)

        expect(result).to include('warning')
        expect(result).to include('unused variable')
      end

      it 'formats message without location' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: nil,
          message: 'syntax error'
        )

        result = formatter.format(message)

        expect(result).to include('error')
        expect(result).to include('syntax error')
      end
    end

    context 'with source line' do
      it 'includes source code and caret' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: 'unexpected token',
          source_line: '%token FOO BAR'
        )

        result = formatter.format(message)

        expect(result).to include('%token FOO BAR')
        expect(result).to include('^')
      end

      it 'generates correct caret length' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: 'unexpected token',
          source_line: '%token FOO BAR'
        )

        result = formatter.format(message)

        # Range is 10 characters (5-15), so caret should be ^~~~~~~~~~
        expect(result).to include('^~~~~~~~~~')
      end
    end

    context 'with notes' do
      it 'includes note messages' do
        note = Lrama::Diagnostics::Message.new(
          type: :note,
          location: location,
          message: 'previously defined here'
        )

        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: 'redefinition',
          notes: [note]
        )

        result = formatter.format(message)

        expect(result).to include('note')
        expect(result).to include('previously defined here')
      end
    end

    context 'with fixit' do
      it 'includes fixit suggestion' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: 'missing semicolon',
          source_line: 'int x = 5',
          fixit: ';'
        )

        result = formatter.format(message)

        expect(result).to include(';')
      end
    end

    context 'with quoted text in message' do
      let(:formatter) { described_class.new(color_enabled: true) }

      before { Lrama::Diagnostics::Color.enabled = true }

      it 'highlights quoted text' do
        message = Lrama::Diagnostics::Message.new(
          type: :error,
          location: location,
          message: "unexpected 'foo'"
        )

        result = formatter.format(message)

        expect(result).to include('foo')
        # The quoted text should be colorized
        expect(result).to include("\e[")
      end
    end
  end

  describe '#format with color' do
    let(:formatter) { described_class.new(color_enabled: true) }

    before { Lrama::Diagnostics::Color.enabled = true }

    it 'colorizes error type' do
      message = Lrama::Diagnostics::Message.new(
        type: :error,
        location: location,
        message: 'test'
      )

      result = formatter.format(message)

      expect(result).to include("\e[")
      expect(result).to include("\e[0m")
    end

    it 'colorizes location' do
      message = Lrama::Diagnostics::Message.new(
        type: :error,
        location: location,
        message: 'test'
      )

      result = formatter.format(message)

      expect(result).to include("\e[")
    end
  end

  describe '#format_all' do
    let(:formatter) { described_class.new(color_enabled: false) }

    it 'formats multiple messages' do
      message1 = Lrama::Diagnostics::Message.new(
        type: :error,
        location: location,
        message: 'first error'
      )

      message2 = Lrama::Diagnostics::Message.new(
        type: :warning,
        location: location,
        message: 'second warning'
      )

      result = formatter.format_all([message1, message2])

      expect(result).to include('first error')
      expect(result).to include('second warning')
    end
  end

  describe 'location formatting' do
    let(:formatter) { described_class.new(color_enabled: false) }

    it 'formats single-line range' do
      message = Lrama::Diagnostics::Message.new(
        type: :error,
        location: location,
        message: 'test'
      )

      result = formatter.format(message)

      expect(result).to include('test.y:10.5-15')
    end

    it 'formats single-column location' do
      loc = double(
        'Location',
        path: 'test.y',
        first_line: 10,
        first_column: 5,
        last_line: 10,
        last_column: 5
      )

      message = Lrama::Diagnostics::Message.new(
        type: :error,
        location: loc,
        message: 'test'
      )

      result = formatter.format(message)

      expect(result).to include('test.y:10.5')
    end

    it 'formats multi-line range' do
      loc = double(
        'Location',
        path: 'test.y',
        first_line: 10,
        first_column: 5,
        last_line: 12,
        last_column: 8
      )

      message = Lrama::Diagnostics::Message.new(
        type: :error,
        location: loc,
        message: 'test'
      )

      result = formatter.format(message)

      expect(result).to include('test.y:10.5-12.8')
    end
  end
end
