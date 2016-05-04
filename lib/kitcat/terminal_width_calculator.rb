module KitCat
  module TerminalWidthCalculator
    class << self
      def calculate
        default_width = 80

        term_width = calculate_term_width

        term_width > 0 ? term_width : default_width
      end

      private

      def calculate_term_width
        if ENV['COLUMNS'] =~ /^\d+$/
          ENV['COLUMNS'].to_i
        elsif tput_case?
          `tput cols`.to_i
        elsif stty_case?
          `stty size`.scan(/\d+/).map(&:to_i)[1]
        end
      rescue
        0
      end

      def tput_case?
        (RUBY_PLATFORM =~ /java/ || !STDIN.tty? && ENV['TERM']) && shell_command_exists?('tput')
      end

      def stty_case?
        STDIN.tty? && shell_command_exists?('stty')
      end

      def shell_command_exists?(command)
        ENV['PATH'].split(File::PATH_SEPARATOR).any? { |d| File.exist? File.join(d, command) }
      end
    end
  end
end
