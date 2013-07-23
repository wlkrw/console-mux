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
require 'eventmachine'
require 'log4r'
require 'ripl/readline/em'

require 'console/mux/buffer_outputter'
require 'console/mux/command'
require 'console/mux/command_set'
require 'console/mux/console_outputter'
require 'console/mux/color_formatter'
require 'console/mux/pty_handler'
require 'console/mux/shell'


module Console
  module Mux
    class Console
      include Log4r

      MARK_PERIOD = 60            # seconds

      BUFFER_LINES = 10000

      attr_reader :commands, :options, :default_options, :formatter, :buffer, :logger

      def initialize(options={})
        @options = options
        @commands = CommandSet.new
        @default_options = Hash.new
        @base_dir = '.'

        @formatter = ColorFormatter.new

        @logger = Logger.new('process')
        logger.add ConsoleOutputter.new('console',
                                        self,
                                        :formatter => formatter)

        @buffer = BufferOutputter.new('buffer',
                                      BUFFER_LINES,
                                      :formatter => formatter)
        logger.add @buffer
      end

      def startup
        EventMachine.run do
          logger.info { 'Initializing' }

          EventMachine.add_periodic_timer(MARK_PERIOD) do
            now = Time.now.strftime('%Y-%m-%d %H:%M')
            logger.info { "#{now} have #{commands.count}" }
          end

          EventMachine.next_tick do
            load(options[:init_file]) if options[:init_file]
          end

          @shell = Shell.new(self)
          Ripl.start :binding => @shell.instance_eval { binding }
          EventMachine.watch_stdin(Ripl::Readline::EmInput,
                                   :on_exit => proc { shutdown })
        end
      end

      def load(file)
        old_base = @base_dir
        @base_dir = File.expand_path(File.dirname(file))
        begin
          @shell.instance_eval(File.read(file), file)
          @last_file = file
        ensure
          @base_dir = old_base
        end
      end

      # Using set_ rather than '=' style accessor so config file needn't
      # use self.default_options =.
      def set_default_options(opts)
        @default_options = opts
      end

      # Run a single command, a sequence of commands, or a sequence of
      # single and parallel commands with default shell argument
      # expansion.
      #
      # Each options hash is merged with the default options and then
      # passed to +Command.new+.
      #
      # If multiple command options are given, run them sequentially
      # one-at-a-time.  Only the final command will remain in the
      # active command list; the others will be removed as they
      # complete and exit.
      #
      # If an array of command options is given, they will be run in
      # parallel, even if part of sequential sequence.  Thus you can
      # specify +run(c1, c2, [c3,c4,c5], c6)+ which will run commands
      # 1 and 2 sequentially, then 3, 4 and 5 in parallel, then
      # finally command 6 only after all previous commands complete.
      #
      # In the following example, the first +ls+ is run, and when it
      # exits the next two +ls+ instances are spawned in parallel.
      # When those two exit, the final +ls+ is run.
      #
      #        run({:command => 'ls'},
      #           [{:command => 'ls'}, {:command => 'ls'}],
      #           {:command => 'ls'})
      #
      # @param [Hash] *opts one or more option hashes passed to +Command.new+.
      def run(*opts_hashes)
        names = add(*opts_hashes).compact
        seq_names(names)
      end

      # Like #run, but does not start any processes.
      def add(*opts_hashes)
        opts_hashes.map do |opts|
          if opts.kind_of? Array
            opts.map { |o| make_command_and_add(o) }
          else
            make_command_and_add(opts)
          end
        end
      end

      def make_command(opts)
        opts = @default_options.merge(opts)
        return if opts[:noop]

        opts[:base_dir] = @base_dir

        begin
          Command.new(opts)
        rescue => e
          # optimistically assume console-mux errors are uninteresting
          first_relevant = e.backtrace.find { |line| !(line =~ %r{lib/console/mux}) }
          # logger.error e.backtrace.join("\n\t")
          logger.error { "#{opts[:command]}: #{e.message} at #{first_relevant}" }
          nil
        end
      end
      private :make_command

      # @return [String, nil] the name of the command or nil if
      # command was noop or if there was an error
      def make_command_and_add(opts)
        if c = make_command(opts)
          commands.add(c)
        end
      end
      private :make_command_and_add

      # Run a sequence of names where each name is the name of a
      # process that may be started.  Each process identified by
      # +names+ will be started, and only after it exits will the
      # remaining processes be started.
      #
      # Each element of +names+ may be a single name or an array of
      # names, in which case all are started in parallel.
      def seq_names(names)
        return unless names.size > 0

        name_or_ary = names.shift
        EventMachine.next_tick do
          # name may be a single name or array of names, so we
          # normalize everything to an array
          to_start = [name_or_ary].flatten
          procs = to_start.map { |n| start(n) }
          
          CommandSet.join(procs) do
            if names.size > 0
              to_start.each { |n| commands.remove(n) }
              seq_names(names)
            end
          end
        end
      end
      private :seq_names

      def status
        puts commands.status
      end

      # Stop all commands in the command set, then destroy the command
      # set, starting with an empty one.
      def reset(&block)
        old_commands = commands
        @commands = CommandSet.new
        old_commands.join(&block)
      end

      def stop(name)
        logger.info { "Stopping #{name}" }
        commands.stop(name)
      end

      def start(name)
        logger.info { "Starting #{name}" }
        commands.start(name)
      end

      def restart(name)
        logger.info { "Restarting #{name}" }
        commands.restart(name)
      end

      def shutdown
        if commands.stopped?
          EventMachine.stop_event_loop
        else
          timer = EventMachine.add_timer(30) do
            logger.error { "could not halt all processes; giving up :(" }
            EventMachine.stop_event_loop
          end

          commands.on(:stopped) do
            EventMachine.cancel_timer(timer)
            EventMachine.stop_event_loop
          end

          commands.stop_all
        end
      end

      def lastlog(arg=//)
        regex = case arg
                when String
                  if arg.eql?(arg.downcase)
                    /#{arg}/i
                  else
                    /#{arg}/
                  end
                when Regexp
                  arg
                else
                  raise ArgumentError, 'need string or regexp'
                end

        @buffer.each do |msg|
          puts msg if msg =~ regex
        end
      end

      def puts(message = '')
        # See http://stackoverflow.com/questions/1512028/gnu-readline-how-do-clear-the-input-line
        #
        # FIXME: Mac OS X 10.8 Mountain Lion seems to no longer have
        # Readline.line_buffer?? Or does it just return nil when
        # empty?
        buf = Readline.line_buffer
        print "\b \b" * buf.size if buf
        print "\r"
        begin
          $stdout.puts message
          $stdout.flush
        ensure
          ::Readline.forced_update_display
        end
      end
    end
  end
end
