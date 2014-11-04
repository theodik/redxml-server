require 'spec_helper'

RSpec.describe RedXML::Server::ClientPool do
  describe '#que' do
    it 'queues client' do
      allow(subject).to receive(:create_thread)
      expect {
        subject.que('test')
      }.to change(subject.queue, :length).by 1
    end

    it 'doesnt create new thread if limit is reached' do
      subject = described_class.new({concurency: 1})
      class_double('Thread').as_stubbed_const.tap do |thread|
        allow(thread).to receive(:new).with(any_args)
      end
      expect(subject).to receive(:create_thread).once.and_call_original
      allow(subject).to receive(:delete_dead_threads)

      subject.que('ẗest1')
      subject.que('test2')
      subject.que('test3')

      expect(subject.queue.length).to eq 3
    end

    it 'delete inactive threads' do
      skip 'Move threads to server worker'
      class_double('Thread').as_stubbed_const.tap do |klass|
        allow(klass).to receive(:new).with(any_args) do
          double('thread').tap do |thread|
            expect(thread).to receive(:status).and_return(nil)
          end
        end
      end

      subject.limit = 5

      spec = self
      5.times { subject.que('test') }
      subject.instance_eval do
        spec.expect(@thread_pool.length).to spec.eq 5
      end
      subject.limit = 3
      subject.que('test')
      subject.instance_eval do
        spec.expect(@thread_pool.length).to spec.eq 1
      end
    end
  end
end
