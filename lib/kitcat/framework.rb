require 'ruby-progressbar'
require 'active_model'
require 'active_support/core_ext'
require 'kitcat/logging'

module Kitcat
  class Framework
    attr_reader :last_item_processed,
                :number_of_items_processed,
                :migration_strategy,
                :logging

    delegate :log_file_path,
             :start_logging, :end_logging,
             :log_success, :log_failure,
             :log_interrupt_callback_start,
             :log_interrupt_callback_finish, to: :logging

    # @params migration_strategy {Object}
    #           Instance implementing the methods of +Kitcat::Callbacks+
    #
    #         migration_name {String} Optional.
    #           The name of the migration. Used as tag in log file name. If not given, a random/unique one is used.
    #
    #         number_of_items_to_process {Integer} Optional.
    #           If given, the processing will stop after processing that many number of items.
    #
    #         progress_bar {Boolean} Optional.
    #           When +True+. it will instantiate a use a progress bar, incrementing that by 1 every time
    #           the +migration_strategy+ finishes processing an item. The total load will be calculated based on the
    #           result of +migration_strategy#criteria#count+.
    #           When +False+, progress bar will not be used
    #
    #         progress_bar_output Optional. Defaults to STDOUT. Anything that responds to
    #           #print, #flush, #tty? and #puts.
    #           It is taken into account only if progress bar is enabled.
    #
    def initialize(migration_strategy,
                   migration_name: nil,
                   number_of_items_to_process: nil,
                   progress_bar: true,
                   progress_bar_output: STDOUT)
      @migration_strategy         = migration_strategy
      @number_of_items_to_process = number_of_items_to_process
      @last_item_processed        = nil
      @progress_bar               = initialize_progress_bar(progress_bar, progress_bar_output)
      @logging                    = Kitcat::Logging.new(migration_strategy, migration_name)
    end

    def execute
      trap_signals

      start_logging

      @number_of_items_processed = 0

      items.each do |item|
        break unless execute_for(item)
      end

    ensure
      end_logging
    end

    def number_of_items_to_process
      @number_of_items_to_process ||= migration_strategy.criteria.count
    end

    def progress_bar?
      !@progress_bar.nil?
    end

    def progress
      return -1 unless progress_bar?
      @progress_bar.progress
    end

    private

    def execute_for(item)
      begin
        if migration_strategy.process(item)

          commit_success(item)

          return false unless process_more?
        else
          commit_failure(item)

          return false
        end
        if @interrupted
          handle_user_interrupt
          return false
        end
      rescue StandardError
        commit_failure(item)
        raise
      end

      true
    end

    def commit_success(item)
      log_success(item)

      @number_of_items_processed += 1

      increment_progress_bar

      @last_item_processed = item
    end

    def commit_failure(item)
      log_failure(item)
    end

    def trap_signals
      @interrupted = false
      Signal.trap('TERM') { @interrupted = true }
      Signal.trap('INT') { @interrupted = true }
    end

    def items
      return enum_for(:items) unless block_given?

      enum = migration_strategy.criteria.each

      loop do
        yield enum.next
      end
    end

    def initialize_progress_bar(progress_bar_flag, output)
      create_progress_bar(output) if progress_bar_flag || progress_bar_flag.nil?
    end

    def create_progress_bar(output)
      @progress_bar = ProgressBar.create(total:  migration_strategy.criteria.count,
                                         output: output,
                                         progress_mark: ' ',
                                         remainder_mark: '-',
                                         length: terminal_width,
                                         format: "%a %bᗧ%i %p%% %e")
    end

    def process_more?
      @number_of_items_to_process.nil? || @number_of_items_processed < @number_of_items_to_process
    end

    def increment_progress_bar
      return unless progress_bar?
      @progress_bar.increment
    end

    def handle_user_interrupt
      log_interrupt_callback_start
      migration_strategy.interrupt_callback if migration_strategy.respond_to?(:interrupt_callback)
      log_interrupt_callback_finish
      true
    end

    # The following is to correctly calculate the width of the terminal
    # so that the progress bar occupies the whole width
    #
    def terminal_width
      TerminalWidthCalculator.calculate
    end
  end
end
