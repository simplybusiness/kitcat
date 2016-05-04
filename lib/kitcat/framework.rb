require 'ruby-progressbar'
require 'active_model'
require 'active_support/core_ext'

module KitCat
  class Framework
    attr_reader :last_item_processed,
                :migration_name,
                :number_of_items_processed,
                :migration_strategy

    # @params migration_strategy {Object}
    #           Instance implementing the methods of +KitCat::Callbacks+
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
      @migration_name             = build_migration_name(migration_name)
      @number_of_items_to_process = number_of_items_to_process
      @last_item_processed        = nil
      @progress_bar               = initialize_progress_bar(progress_bar, progress_bar_output)
    end

    def execute
      @interrupted = false
      Signal.trap('TERM') { @interrupted = true }
      Signal.trap('INT') { @interrupted = true }
      start_logging

      @number_of_items_processed = 0

      items.each do |item|
        if migration_strategy.process(item)

          log_success(item)

          @number_of_items_processed += 1

          increment_progress_bar

          @last_item_processed = item

          break unless process_more?
        else
          log_failure(item)

          break
        end
        if @interrupted
          handle_user_interrupt
          break
        end
      end
      end_logging
    end

    def number_of_items_to_process
      @number_of_items_to_process ||= migration_strategy.criteria.count
    end

    def log_file_path
      @log_file_path ||= File.join(log_dir, build_log_file_name)
    end

    def progress_bar?
      !@progress_bar.nil?
    end

    def progress
      return -1 unless progress_bar?
      @progress_bar.progress
    end

    private

    def items
      return enum_for(:items) unless block_given?

      enum = migration_strategy.criteria.each

      loop do
        yield enum.next
      end
    end

    def log_dir
      @log_dir ||= FileUtils.mkdir_p(File.join(Dir.pwd, 'log'))
    end

    def build_log_file_name
      "migration-#{migration_name}-#{timestamp}.log"
    end

    def timestamp
      Time.now.to_s(:number)
    end

    def build_migration_name(migration_name)
      result = migration_name || migration_strategy.class.name.delete(':').underscore.upcase
      result.gsub(/\W/, '').upcase
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

    def start_logging
      logger.info 'Start Processing...'
    end

    def end_logging
      logger.info '...end of processing'
    end

    def logger
      @logger ||= Logger.new(log_file_path)
    end

    def log_success(item)
      log_line(item) { |method| logger.info "...successfully processed item: #{item.try(method)}" }
    end

    def log_failure(item)
      log_line(item) { |method| logger.error "...error while processing item: #{item.try(method)}" }
    end

    def log_line(item)
      method = item.respond_to?(:to_log) ? :to_log : :to_s
      yield method
    end

    def log_interrupt_callback_start
      logger.info '...user interrupted, calling interrupt callback on migration strategy...'
    end

    def log_interrupt_callback_finish
      logger.info '......end of interrupt callback after user interruption'
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
