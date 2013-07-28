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
require 'console/mux/events'

module Console
  module Mux
    class CommandSet
      include Console::Mux::Events

      class << self
        # Yield to the block only after all processes are stopped.
        # Does not check that all processes are actually running; just
        # waits for an +:exit+ event from each.
        #
        # @param [Array<Process>] processes
        def join(processes, &block)
          q = EventMachine::Queue.new

          processes.each do |proc|
            proc.on(:exit) { q.push :exit }
          end

          (processes.size - 1).times { q.pop {} }
          q.pop { block.call }  # all have exited
        end
      end

      attr_reader :max_width

      def initialize
        @max_width = 0
        @commands = Array.new
        @commands_by_name = Hash.new

        @processes = Hash.new
        @stopped_at = Hash.new
      end

      # Add a command (see #add) and start it (see #start).
      def add_and_start(command)
        name = add(command)
        start(name)
      end

      # Add a command to this CommandSet.
      #
      # @param [Command] command
      #
      # @return [String] the command name, which may be different from
      # +command.name+ if required to be unique within this CommandSet
      def add(command)
        name = unique_name(command.name)

        @commands << command
        @commands_by_name[name] = command
        @max_width = [@max_width, name.size].max

        name
      end

      def remove(name)
        return unless @commands_by_name[name]

        stop(name) rescue nil
        @stopped_at.delete(name)
        @commands.delete(@commands_by_name.delete(name))
      end

      # TODO: make this work?
      # def merge(command)
      #   if i = @commands.first_index(command)
      #     @commands[i] = command
      #     @commands_by_name[command.name] = command
      #   else
      #     add(command)
      #   end
      # end

      def include?(command)
        @commands.include?(command)
      end

      def stopped?
        @processes.empty?
      end

      def each(&block)
        @commands.each(&block)
      end

      def [](name)
        @commands_by_name[name]
      end

      def start(name)
        if proc = @processes[name]
          raise "already have process for #{name}: #{proc.pid}"
        end
        
        @stopped_at.delete(name)
        proc = Process.start(@commands_by_name[name], name)
        proc.on(:exit) do
          @processes.delete(name)
          @stopped_at[name] = Time.now
          fire(:stopped) if @processes.empty?
        end
        @processes[name] = proc
        proc
      end

      def stop(name)
        if proc = @processes.delete(name)
          proc.stop
        else
          raise "no process for #{name}"
        end
      end

      def stop_all
        @processes.each do |name, proc|
          proc.stop
        end
      end

      # When all currently-running processes stop, yield to the block
      def join(&block)
        self.class.join(@processes.values, &block)
      end

      # Stop and then start the process +name+.
      def restart(name)
        if proc = @processes[name]
          proc.on(:exit) do
            start(name)
          end
          proc.stop
        elsif @commands_by_name[name]
          start(name)
        else
          raise "no process for #{name}"
        end
      end

      def pretty_seconds(secs)
        if secs < 60
          "#{secs} s"
        elsif secs < (60 * 60)
          "#{secs/60} min"
        elsif secs < (60 * 60 * 24)
          "#{secs/60/60} hr"
        else
          "%0.1f days" % (secs/60.0/60.0/24.0)
        end
      end

      def pretty_bytes(bytes)
        if bytes < 1024
          "#{bytes}B"
        elsif bytes < 1024 * 1024
          "#{bytes/1024} kiB"
        elsif bytes < 1024* 1024 * 1024
          "#{bytes/1024/1024} MiB"
        else
          "%0.2d GiB" % (bytes.to_f/(1024**3))
        end
      end

      def status
        fmt = "%-#{max_width}s %8s %12s %8s %10s\n"

        rows = []
        rows << fmt % ['NAME', 'PID', 'RSS', 'TIME', 'CPUTIME']
        @commands_by_name.each do |name, c|
          pid, rss, time, cputime =
            if proc = @processes[name]
              [proc.pid.to_s,
               pretty_bytes(proc.rss),
               proc.etime,
               proc.cputime]
            elsif @stopped_at[name]
              downtime = Time.now.to_i - @stopped_at[name].to_i
              ['-', "  down #{pretty_seconds(downtime)}", nil, nil]
            else
              ['-', "        (pending)", nil, nil]
            end
          
          rows << (fmt % [name, pid, rss, time, cputime])
        end

        rows
      end

      def count
        "#{@commands.size} commands with #{@processes.size} running"
      end

      private 

      # Generate a unique command name based on `name`.  If there is
      # already a command `name`, a digit will be appended, starting
      # at 2, and increasing until an unused name is found.
      def unique_name(name)
        if @commands_by_name.include?(name)
          count = 2
          name2 = nil
          while (name2 = name + count.to_s) && @commands_by_name.include?(name2)
            count += 1
          end
          name2
        else
          name
        end
      end
    end
  end
end