require 'spec_helper'
require 'tempfile'
require 'redxml/server/cli'

RSpec.describe RedXML::Server::CLI do
  before do
    RedXML::Server.options = {}
  end

  describe '#parse' do
    it 'sets verbose' do
      subject.parse(['redxml-server', '-v'])
      expect(RedXML::Server.logger.level).to eq Logger::DEBUG
    end

    it 'sets concurency' do
      subject.parse(['redxml-server', '-C', '10'])
      expect(RedXML::Server.options[:concurency]).to eq 10
    end


    it 'sets host to bind' do
      subject.parse(['redxml-server', '-b', 'test-host'])
      expect(RedXML::Server.options[:bind]).to eq 'test-host'
    end

    it 'sets port to bind' do
      subject.parse(['redxml-server', '-p', '33965'])
      expect(RedXML::Server.options[:port]).to eq 33965
    end

    context 'with logfile' do
      before do
        @log_path   = '/tmp/redxml.log'
        @old_logger = RedXML::Server.logger
      end

      after do
        RedXML::Server.logger = @old_logger
      end

      it 'creates and writes to a logfile' do
        subject.parse(['redxml-server', '-L', @log_path])

        RedXML::Server.logger.info('test message')

        expect(File.read(@log_path)).to match /test message/

      end

      it 'appends message to a logfile' do
        File.open(@log_path, 'w') do |f|
          f.puts 'already existant log message'
        end

        subject.parse(['redxml-server', '-L', @log_path])

        RedXML::Server.logger.info('test message')

        log_content = File.read(@log_path)
        expect(log_content).to match /test message/
        expect(log_content).to match /already existant log message/
      end
    end
  end

  context 'with pidfile' do
    before do
      @tmp_file = Tempfile.new('redxml-test')
      @tmp_path = @tmp_file.path
      @tmp_file.close!

      subject.parse(['redxml-server', '-P', @tmp_path])
    end

    after do
      File.unlink @tmp_path if File.exist? @tmp_path
    end

    it 'sets pidfile' do
      expect(RedXML::Server.options[:pidfile]).to eq @tmp_path
    end

    it 'writes a pidfile' do
      pid = File.read(@tmp_path).strip.to_i
      expect(pid).to eq Process.pid
    end
  end
end
