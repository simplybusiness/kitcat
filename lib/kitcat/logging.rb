module Kitcat
  # +Kitcat::Logging+ is used to encapsulate the functionality of +Framework+ related to
  # logging.
  #
  # It needs to be initialized with the +migration_name+ because this is used to build the
  # relevant log filename.
  #
  class Logging
    attr_reader :migration_name, :migration_strategy

    def initialize(migration_strategy, migration_name)
      @migration_name = build_migration_name(migration_name, migration_strategy)
    end

    def log_file_path
      @log_file_path ||= File.join(log_dir, build_log_file_name)
    end

    def start_logging
      logger.info 'Start Processing...'
    end

    def end_logging
      logger.info '...end of processing'
    end

    def log_success(item)
      log_line(item) { |method| logger.info "...successfully processed item: #{item.try(method)}" }
    end

    def log_failure(item)
      log_line(item) { |method| logger.error "...error while processing item: #{item.try(method)}" }
    end

    def log_interrupt_callback_start
      logger.info '...user interrupted, calling interrupt callback on migration strategy...'
    end

    def log_interrupt_callback_finish
      logger.info '......end of interrupt callback after user interruption'
    end

    private

    def build_migration_name(migration_name, migration_strategy)
      result = migration_name || migration_strategy.class.name.delete(':').underscore.upcase
      result.gsub(/\W/, '').upcase
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

    def logger
      @logger ||= Logger.new(log_file_path)
    end

    def log_line(item)
      method = item.respond_to?(:to_log) ? :to_log : :to_s
      yield method
    end
  end
end
