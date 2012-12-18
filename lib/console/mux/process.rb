#
# Copyright (C) 2012 Common Ground Publishing
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'log4r'
require 'pty'

require 'console/mux/env_with_merged'
require 'console/mux/pty_handler'
require 'console/mux/events'

module Console
  module Mux
    class Process
      include Log4r
      include Console::Mux::Events

      attr_reader :command, :pid, :logger, :started_at, :name

      class << self
        alias_method :start, :new
      end

      def initialize(command, name = nil)
        @command = command
        @name = name
        @logger = Logger["process::#{name}"] || Logger.new("process::#{name}")
        start
      end

      def stop(&block)
        if @handler
          @handler.detach
        end
      end

      def running?
        @handler != nil
      end

      def name
        command.name
      end

      def to_s
        "#{command} (#{running? ? pid : 'stopped'})"
      end

      # Called by the child handler
      def unbind
        @stdin.close rescue nil
        @stdout.close rescue nil

        pid2, status = ::Process.waitpid2(pid, ::Process::WNOHANG)
        if pid2
          on_exit(status)
        else
          try_kill(['INT', 'TERM', 'KILL'])
        end
      end

      def receive_line(line)
        logger.info { line }
      end

      # @return [Integer] uptime in seconds
      def uptime
        Time.now.to_i - started_at.to_i
      end

      # Capture the output of a single field using the 'ps' command.
      def ps1(field)
        `ps -o #{field}= -p #{pid}`.strip
      end

      # @return [String] elapsed time
      def etime
        ps1('etime')
      end

      # @return [Integer] resident size in bytes
      def rss
        ps1('rss').to_i * 1024
      end

      # @return [String] cputime in 
      def cputime
        ps1('cputime')
      end

      protected

      # This is for comparison purposes.
      def to_hash
        {
          :name => name,
          :command => command,
          :opts => opts
        }
      end

      private

      # Clean some common crud from ENV before spawning a command.
      def with_clean_env(env)
        ENV.restore do
          ENV.delete_if do |k,_|
            k.start_with?('BUNDLE_') ||
              k == 'RUBY' ||
              k.start_with?('GEM_')
          end
          ENV.update(env)
          yield
        end
      end

      def start
        raise 'already started' if @handler

        @started_at = Time.now

        stdin, stdout, pid = Dir.chdir command.dir do
          with_clean_env(command.env) do
            PTY.spawn(command.commandline)
          end
        end

        @stdin = stdin
        @stdout = stdout
        @pid = pid
        
        logger.info { "in #{File.expand_path(command.dir)}" }
        logger.info { "with #{command.env.to_a.map{|k,v| "#{k}=#{v}"}.join(' ')}" }
        logger.info { command }
        logger.info { "started process #{pid}" }
        
        @handler = EventMachine.attach(stdout, PTYHandler, self)
      end

      def try_kill(signals)
        if (signals.size > 0)
          signal = signals.shift
          logger.info "sending #{signal} to #{pid}"
          ::Process.kill(signal, pid) rescue nil
          
          check(20, 0.1) do
            try_kill(signals)
          end
        else
          on_exit(nil)
        end
      end

      def check(tries, period, &on_fail)
        if tries <= 0
          on_fail.call
          return
        end

        EventMachine.add_timer(period) do
          pid2, status = ::Process.waitpid2(pid, ::Process::WNOHANG)
          if !pid2
            check(tries - 1, period, &on_fail)
          else
            on_exit(status)
          end
        end
      end

      def on_exit(status)
        begin
          if status == nil
            logger.warn { "error killing process #{pid}" }
          elsif status.signaled?
            signo = status.termsig
            signm = SignalException.new(signo).signm
            logger.warn { "process #{pid} exited with uncaught signal #{signm} (#{signo})" }
          elsif status.exited?
            logger.info { "process #{pid} exited #{status.exitstatus}" }
          else
            logger.warn { "process #{pid} exited #{status.inspect}" }
          end
        ensure
          @handler = nil
          fire(:exit)
        end
      end
    end
  end
end