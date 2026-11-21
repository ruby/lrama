# frozen_string_literal: true

RSpec.describe Lrama::Diagnostics::Color do
  after do
    described_class.enabled = false
  end

  describe '.colorize' do
    context 'when enabled' do
      before { described_class.enabled = true }

      it 'wraps text with ANSI codes for semantic styles' do
        result = described_class.colorize('error', :error)
        expect(result).to include("\e[")
        expect(result).to include('error')
        expect(result).to end_with("\e[0m")
      end

      it 'wraps text with ANSI codes for basic styles' do
        result = described_class.colorize('text', :bold, :red)
        expect(result).to include("\e[1m")
        expect(result).to include("\e[31m")
        expect(result).to include('text')
        expect(result).to end_with("\e[0m")
      end

      it 'returns plain text for empty styles' do
        result = described_class.colorize('text')
        expect(result).to eq('text')
      end

      it 'returns plain text for unknown styles' do
        result = described_class.colorize('text', :unknown_style)
        expect(result).to eq('text')
      end
    end

    context 'when disabled' do
      before { described_class.enabled = false }

      it 'returns plain text' do
        result = described_class.colorize('error', :error)
        expect(result).to eq('error')
      end

      it 'converts non-string to string' do
        result = described_class.colorize(123, :error)
        expect(result).to eq('123')
      end
    end
  end

  describe '.strip' do
    it 'removes ANSI escape sequences' do
      colored = "\e[1;31merror\e[0m"
      expect(described_class.strip(colored)).to eq('error')
    end

    it 'handles text without escape sequences' do
      expect(described_class.strip('plain text')).to eq('plain text')
    end

    it 'handles multiple escape sequences' do
      colored = "\e[1m\e[31mhello\e[0m \e[32mworld\e[0m"
      expect(described_class.strip(colored)).to eq('hello world')
    end
  end

  describe '.tty?' do
    it 'returns true for IO with tty? returning true' do
      io = instance_double(IO, tty?: true)
      expect(described_class.tty?(io)).to be true
    end

    it 'returns false for IO with tty? returning false' do
      io = instance_double(IO, tty?: false)
      expect(described_class.tty?(io)).to be false
    end

    it 'returns false for objects without tty? method' do
      obj = Object.new
      expect(described_class.tty?(obj)).to be false
    end
  end

  describe '.should_colorize?' do
    context 'with NO_COLOR environment variable' do
      around do |example|
        original = ENV['NO_COLOR']
        ENV['NO_COLOR'] = '1'
        example.run
        if original.nil?
          ENV.delete('NO_COLOR')
        else
          ENV['NO_COLOR'] = original
        end
      end

      it 'returns false regardless of mode' do
        expect(described_class.should_colorize?(:always)).to be false
        expect(described_class.should_colorize?(:auto)).to be false
        expect(described_class.should_colorize?(:never)).to be false
      end
    end

    context 'without NO_COLOR environment variable' do
      around do |example|
        original = ENV['NO_COLOR']
        ENV.delete('NO_COLOR')
        example.run
        ENV['NO_COLOR'] = original if original
      end

      it 'returns true for :always mode' do
        expect(described_class.should_colorize?(:always)).to be true
      end

      it 'returns false for :never mode' do
        expect(described_class.should_colorize?(:never)).to be false
      end

      it 'returns false for unknown mode' do
        expect(described_class.should_colorize?(:unknown)).to be false
      end
    end
  end

  describe '.setup' do
    around do |example|
      original_no_color = ENV['NO_COLOR']
      ENV.delete('NO_COLOR')
      example.run
      ENV['NO_COLOR'] = original_no_color if original_no_color
    end

    it 'enables color for :always mode' do
      described_class.setup(:always)
      expect(described_class.enabled).to be true
    end

    it 'disables color for :never mode' do
      described_class.setup(:never)
      expect(described_class.enabled).to be false
    end
  end

  describe '.default_mode' do
    around do |example|
      original = ENV['LRAMA_COLOR']
      example.run
      if original.nil?
        ENV.delete('LRAMA_COLOR')
      else
        ENV['LRAMA_COLOR'] = original
      end
    end

    it 'returns :always when LRAMA_COLOR is "always"' do
      ENV['LRAMA_COLOR'] = 'always'
      expect(described_class.default_mode).to eq(:always)
    end

    it 'returns :always when LRAMA_COLOR is "yes"' do
      ENV['LRAMA_COLOR'] = 'yes'
      expect(described_class.default_mode).to eq(:always)
    end

    it 'returns :never when LRAMA_COLOR is "never"' do
      ENV['LRAMA_COLOR'] = 'never'
      expect(described_class.default_mode).to eq(:never)
    end

    it 'returns :never when LRAMA_COLOR is "no"' do
      ENV['LRAMA_COLOR'] = 'no'
      expect(described_class.default_mode).to eq(:never)
    end

    it 'returns :auto when LRAMA_COLOR is not set' do
      ENV.delete('LRAMA_COLOR')
      expect(described_class.default_mode).to eq(:auto)
    end

    it 'returns :auto for unknown values' do
      ENV['LRAMA_COLOR'] = 'invalid'
      expect(described_class.default_mode).to eq(:auto)
    end
  end

  describe 'CODES' do
    it 'includes reset code' do
      expect(described_class::CODES[:reset]).to eq("\e[0m")
    end

    it 'includes basic colors' do
      expect(described_class::CODES[:red]).to eq("\e[31m")
      expect(described_class::CODES[:green]).to eq("\e[32m")
      expect(described_class::CODES[:yellow]).to eq("\e[33m")
    end

    it 'includes style codes' do
      expect(described_class::CODES[:bold]).to eq("\e[1m")
      expect(described_class::CODES[:strikethrough]).to eq("\e[9m")
    end
  end

  describe 'SEMANTIC_STYLES' do
    it 'defines error style' do
      expect(described_class::SEMANTIC_STYLES[:error]).to eq([:bold, :red])
    end

    it 'defines warning style' do
      expect(described_class::SEMANTIC_STYLES[:warning]).to eq([:bold, :magenta])
    end

    it 'defines note style' do
      expect(described_class::SEMANTIC_STYLES[:note]).to eq([:bold, :cyan])
    end
  end
end
