# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  module Diagnostics
    module Color
      CODES = {
        reset:         "\e[0m",
        bold:          "\e[1m",
        strikethrough: "\e[9m",

        red:     "\e[31m",
        green:   "\e[32m",
        yellow:  "\e[33m",
        magenta: "\e[35m",
        cyan:    "\e[36m",
        white:   "\e[37m"
      }.freeze

      SEMANTIC_STYLES = {
        error:        [:bold, :red],
        warning:      [:bold, :magenta],
        note:         [:bold, :cyan],
        location:     [:bold, :white],
        caret:        [:green],
        quote:        [:yellow],
        unexpected:   [:red],
        fixit_insert: [:green],
        fixit_delete: [:strikethrough, :red]
      }.freeze

      class << self
        # @rbs () -> bool
        def enabled
          @enabled ||= false
        end

        # @rbs (bool) -> bool
        def enabled=(value)
          @enabled = value
        end

        # @rbs (untyped text, *Symbol styles) -> String
        def colorize(text, *styles)
          return text.to_s unless @enabled
          return text.to_s if styles.empty?

          codes = resolve_styles(styles)
          return text.to_s if codes.empty?

          "#{codes.join}#{text}#{CODES[:reset]}"
        end

        # @rbs (untyped text) -> String
        def strip(text)
          text.to_s.gsub(/\e\[[0-9;]*m/, '')
        end

        # @rbs (?IO io) -> bool
        def tty?(io = $stderr)
          io.respond_to?(:tty?) && io.tty?
        end

        # @rbs (Symbol mode, ?IO io) -> bool
        def should_colorize?(mode, io = $stderr)
          return false if ENV.key?('NO_COLOR')

          case mode
          when :always then true
          when :never  then false
          when :auto   then tty?(io) && supports_color?
          else              false
          end
        end

        # @rbs (Symbol mode, ?IO io) -> bool
        def setup(mode, io = $stderr)
          @enabled = should_colorize?(mode, io)
        end

        # @rbs () -> Symbol
        def default_mode
          case ENV['LRAMA_COLOR']&.downcase
          when 'always', 'yes' then :always
          when 'never', 'no'   then :never
          else                      :auto
          end
        end

        private

        # @rbs (Array[Symbol] styles) -> Array[String]
        def resolve_styles(styles)
          styles.flat_map { |style|
            if SEMANTIC_STYLES.key?(style)
              SEMANTIC_STYLES[style].map { |s| CODES[s] }
            elsif CODES.key?(style)
              [CODES[style]]
            else
              []
            end
          }.compact
        end

        # @rbs () -> bool
        def supports_color?
          term = ENV['TERM']
          return false if term.nil? || term.empty? || term == 'dumb'

          term.include?('color') ||
            term.include?('256') ||
            term.include?('xterm') ||
            term.include?('screen') ||
            term.include?('vt100') ||
            term.include?('ansi') ||
            term.include?('linux') ||
            term.include?('cygwin') ||
            term.include?('rxvt')
        end
      end
    end
  end
end
