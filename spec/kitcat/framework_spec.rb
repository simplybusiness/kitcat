require 'spec_helper'

describe KitCat::Framework do
  # --------------------------------------------
  # hosting class example
  #
  module KitCat
    module Test
      class Strategy
        # Helping class that will use to wrap the items so that framework will log whatever the strategy wants
        # Note that framework will be calling the #to_log for each item logged in the log file.
        #
        class Item < Struct.new(:item)
          def to_log
            item.to_s
          end
        end

        attr_reader :items            # not necessary for the framework to work, it's here to ease testing
        attr_accessor :failed_item    # not necessary for the framework to work, it's here to ease testing
        attr_accessor :exception_item # not necessary for the framework to work, it's here to ease testing

        # This particular Strategy is initialized in such a way in order to ease the testing.
        # It will be holding a list of continuous integers, starting from +1+ and incrementing
        # by 1. Actually, it will be [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].
        #
        # The +failed_item+ is a helper to test the Framework for the items that fail.
        # You will see that some tests of the Framework will set this to an integer
        # that will be supposed to be failing item.
        #
        # The +exception_item+ is a helper to test the Framework for the item that will make process raise an exception.
        # You will see that some tests of the Framework will set this to an integer
        # that will be supposed to be items raising exceptions.
        #
        def initialize
          @items = (1..count).to_a
          @failed_item = -1
          @exception_item = -1
        end

        # need to implement in order to support framework
        #
        def process(item)
          raise StandardError, 'Cannot process this item' if @exception_item == item.item
          @failed_item != item.item
        end

        # need to implement in order to support framework
        #
        def criteria
          return enum_for(:criteria) unless block_given?

          enum = @items.each

          loop do
            yield KitCat::Test::Strategy::Item.new(enum.next)
          end
        end

        # Optional interrupt call back implementation.
        #
        # This callback is called before the end of the processing
        # when the user decides to prematurely interrupt the process.
        #
        def interrupt_callback; end

        private

        # need to implement in order to support framework
        #
        def count
          10
        end
      end
    end
  end
  # end of hosting class example
  # ----------------------------------------------------

  let!(:test_strategy_class) { KitCat::Test::Strategy }
  let!(:failed_item) { -1 }
  let!(:exception_item) { -1 }
  let(:strategy) do
    result = test_strategy_class.new
    result.failed_item = failed_item
    result.exception_item = exception_item
    result
  end
  let(:migration_name)             { nil }
  let(:number_of_items_to_process) { nil }
  let(:progress_bar_output)        { double('printer').as_null_object }
  let(:progress_bar)               { nil }

  subject do
    described_class.new(strategy, migration_name:             migration_name,
                                  number_of_items_to_process: number_of_items_to_process,
                                  progress_bar:               progress_bar,
                                  progress_bar_output:        progress_bar_output)
  end

  after do
    FileUtils.rm_rf(subject.log_file_path)
  end

  describe '#number_of_items_to_process' do
    context 'when number of items to process is set' do
      let(:number_of_items_to_process) { 5 }

      it 'returns the number of items to process' do
        expect(subject.number_of_items_to_process).to eq(number_of_items_to_process)
      end
    end

    context 'when number of items to process is not set' do
      let(:number_of_items_to_process) { nil }

      context 'when there are some items to process' do
        before do
          expect(strategy.criteria.count).to be >= 1
        end

        it 'returns the total number of items to process' do
          expect(subject.number_of_items_to_process).to eq(strategy.criteria.count)
        end
      end

      context 'when there are not any items to process' do
        before do
          allow(strategy).to receive(:criteria).and_return([])
        end
        it 'returns zero' do
          expect(subject.number_of_items_to_process).to eq(0)
        end
      end
    end
  end

  describe '#number_of_items_processed' do
    context 'when there are no items to process' do
      before do
        allow(strategy).to receive(:criteria).and_return([])
      end

      it 'returns zero' do
        subject.execute

        expect(subject.number_of_items_processed).to be_zero
      end
    end

    context 'when number of items to process is not set' do
      let(:number_of_items_to_process) { nil }

      context 'when there are some items to process' do
        before do
          expect(strategy.criteria.count).to be >= 1
        end

        it 'processes all the items and returns items processed' do
          subject.execute

          expect(subject.number_of_items_processed).to eq(strategy.criteria.count)
        end
      end
    end

    context 'when number of items to process is set' do
      let(:number_of_items_to_process) { 5 }

      context 'and it is less than total number of items' do
        before do
          expect(strategy.criteria.count).to be > number_of_items_to_process
        end

        it 'only processes the number of items requested' do
          subject.execute

          expect(subject.number_of_items_processed).to eq(number_of_items_to_process)
          expect(subject.number_of_items_processed).to be < strategy.criteria.count
        end
      end

      context 'and it is equal to the total number of items' do
        let(:number_of_items_to_process) { strategy.criteria.count }

        it 'processes all the items and returns items processed' do
          subject.execute

          expect(subject.number_of_items_processed).to eq(strategy.criteria.count)
        end
      end

      context 'and it is greater than total number of items' do
        let(:number_of_items_to_process) { strategy.criteria.count + 1 }

        it 'processes all items and returns items processed' do
          subject.execute

          expect(subject.number_of_items_processed).to eq(strategy.criteria.count)
        end
      end
    end
  end

  describe '#last_item_processed' do
    context 'when there are some items to process' do
      before do
        expect(strategy.criteria.count).to be >= 1
      end

      it 'returns the last item processed' do
        subject.execute

        last_item_processed = subject.last_item_processed

        expect(last_item_processed.item).to eq(strategy.items.last)
      end

      context 'when the number of items to process is set' do
        let(:number_of_items_to_process) { 5 }
        let(:last_item_processed) { strategy.items[number_of_items_to_process - 1] }

        context 'and it is less than total number of items' do
          before do
            expect(strategy.criteria.count).to be > number_of_items_to_process
          end

          it 'returns the correct last item processed' do
            subject.execute

            expect(subject.last_item_processed.item).to eq(last_item_processed)
          end
        end
      end
    end

    context 'when there are no items to process' do
      before do
        allow(strategy).to receive(:criteria).and_return([])
      end

      it 'returns nil' do
        subject.execute

        last_item_processed = subject.last_item_processed
        expect(last_item_processed).to be_nil
      end
    end
  end

  describe '#progress_bar?' do
    context 'when framework instantiated without progress bar option' do
      it 'returns true that progress bar is enabled' do
        expect(subject.progress_bar?).to eq(true)
      end
    end

    context 'when framework instantiated with progress bar option off' do
      let(:progress_bar) { false }

      it 'returns false that progress bar is disabled' do
        expect(subject.progress_bar?).to eq(false)
      end
    end

    context 'when framework instantiated with progress bar option on' do
      let(:progress_bar) { true }

      it 'returns true that progress bar is enabled' do
        expect(subject.progress_bar?).to eq(true)
      end
    end
  end

  describe '#execute' do
    # Important: Lots of testing in this context, depends on the fact that the Strategy is an
    # ordered array of continuous series of integers starting from 1.
    # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    #
    # This has been done in order to simplify the testing. We do not believe it affects or bias the
    # testing of the Framework itself.
    #

    describe 'logging' do
      it 'generates a log file' do
        subject.execute

        log_file_path = subject.log_file_path

        expect(File.exist?(log_file_path)).to eq(true)
      end

      it 'generates a log file with first payload line as Start Processing...' do
        subject.execute

        log_lines = File.readlines(subject.log_file_path)
        expect(log_lines[1]).to include('Start Processing...')
      end

      it 'generates a log file with last payload line as ...end of processing' do
        subject.execute

        log_lines = File.readlines(subject.log_file_path)
        expect(log_lines[-1]).to include('...end of processing')
      end

      context 'when process is interrupted with SIGINT or SIGTERM' do
        %w(INT TERM).each do |signal|
          before do
            allow(strategy).to receive(:process) do
              Process.kill(signal, Process.pid)
              sleep(1)
              true
            end
          end

          it 'generates a log file with third to last payload line as calling of interrupt callback process' do
            # make sure that the strategy clean up does not add any lines for this test
            allow(strategy).to receive(:interrupt_callback)

            subject.execute

            log_lines = File.readlines(subject.log_file_path)
            expect(log_lines[-3]).to include('user interrupted, calling interrupt callback on migration strategy...')
          end

          it 'generates a log file with second to last payload line as ...end of interrupt callback' do
            subject.execute

            log_lines = File.readlines(subject.log_file_path)
            expect(log_lines[-2]).to include('...end of interrupt callback after user interruption')
          end
        end
      end

      context 'when there are items to process' do
        let(:minimum_number_of_items) { 5 }

        before do
          expect(strategy.criteria.count).to be > minimum_number_of_items
        end

        it 'generates a log file with success lines for each item processed successfully' do
          subject.execute

          log_lines = File.readlines(subject.log_file_path)
          expect(log_lines.size).to eq(3 + strategy.criteria.count) #   1 for the default log line at start
          # + 1 for the start processing
          # + 1 for the end processing
          # + lines to process

          log_lines[2..(2 + strategy.criteria.count - 1)].each_with_index do |log_line, index|
            expect(log_line).to include("successfully processed item: #{KitCat::Test::Strategy::Item.new(strategy.items[index]).to_log}")
          end
        end

        context 'when there is an item that cannot be processed' do
          let(:failed_item) { (1..minimum_number_of_items).to_a.sample }

          it 'generates a log file with a failure line for the particular item at the end' do
            subject.execute

            log_lines = File.readlines(subject.log_file_path)
            expect(log_lines.size).to be >= 3 #   1 for the default log line at start
            # + 1 for the start processing
            # + 1 for the end of processing
            # + more for the processed items

            log_lines[2..(2 + strategy.items.find_index(failed_item).to_i - 1)].each_with_index do |log_line, index|
              expect(log_line).to include("successfully processed item: #{KitCat::Test::Strategy::Item.new(strategy.items[index]).to_log}")
            end

            # note that last line is for the end of processing
            expect(log_lines[-2]).to include("error while processing item: #{KitCat::Test::Strategy::Item.new(strategy.items.select { |i| failed_item == i }.first).to_log}")
          end
        end

        context 'when there is an item that makes strategy raise an exception' do
          let(:exception_item) { (1..minimum_number_of_items).to_a.sample }

          it 'generates a log file with a failure line for the particular item at the end' do
            expect do
              subject.execute
            end.to raise_error { StandardError }

            log_lines = File.readlines(subject.log_file_path)
            expect(log_lines.size).to be >= 3 #   1 for the default log line at start
            # + 1 for the start processing
            # + 1 for the end of processing
            # + more for the processed items

            log_lines[2..(2 + strategy.items.find_index(exception_item).to_i - 1)].each_with_index do |log_line, index|
              expect(log_line).to include("successfully processed item: #{KitCat::Test::Strategy::Item.new(strategy.items[index]).to_log}")
            end

            # note that last line is for the end of processing
            expect(log_lines[-2]).to include("error while processing item: #{KitCat::Test::Strategy::Item.new(strategy.items.select { |i| exception_item == i }.first).to_log}")
          end
        end
      end
    end

    describe 'progress bar' do
      context 'when there are items to process' do
        let(:minimum_number_of_items) { 5 }

        before do
          expect(strategy.criteria.count).to be > minimum_number_of_items
        end

        it 'increments its progress for each one of the items processed successfully' do
          expect do
            subject.execute
          end.to change { subject.progress }.by(strategy.criteria.count)
        end

        context 'when there is an item that cannot be processed' do
          let(:failed_item) { (1..minimum_number_of_items).to_a.sample }

          it 'increments progress bar only for the processed items' do
            expect do
              subject.execute
            end.to change { subject.progress }.by(strategy.items.find_index(failed_item).to_i)
          end
        end
      end
    end

    context 'when process is interrupted' do
      before do
        # we are simulating a user interrupt during item processing
        allow(strategy).to receive(:process) do
          Process.kill('INT', Process.pid)
          sleep(1)
          true
        end
      end

      context 'when strategy does not support interrupt clean up' do
        before do
          strategy.class.send :remove_method, :interrupt_callback
          expect(strategy).not_to respond_to(:interrupt_callback)
        end

        it 'does not break' do
          subject.execute
        end
      end
    end
  end

  describe '#progress' do
    context 'when progress bar is not enabled' do
      let(:progress_bar) { false }
      it 'returns -1' do
        expect(subject.progress).to eq(-1)
      end
    end

    context 'when progress bar is enabled' do
      let(:progress_bar) { true }
      it 'returns whatever the internal progress bar progress is' do
        progress_result = double('progress result')
        progress_bar = subject.instance_variable_get(:@progress_bar)
        allow(progress_bar).to receive(:progress).and_return(progress_result)

        expect(subject.progress).to eq(progress_result)
      end
    end
  end
end
