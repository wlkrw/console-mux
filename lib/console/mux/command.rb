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
require 'console/mux/util'
require 'console/mux/process'
require 'console/mux/run_with'
require 'pathname'

module Console
  module Mux
    class Command
      include Util

      class << self
        def option_reader(*syms)
          syms.each do |sym|
            define_method(sym) do
              self[sym]
            end
          end
        end

        def option_writer(*syms)
          syms.each do |sym|
            define_method("#{sym}=") do |val|
              self[sym] = val
            end
          end
        end

        def option_accessor(*syms)
          option_reader(*syms)
          option_writer(*syms)
        end
      end

      attr_reader :opts, :commandline

      option_accessor :name, :command, :env, :run_with, :chdir

      # @param opts execution options arbitrary keys and values, but some are special
      #
      # @option opts [Boolean] :noop if true, the command will not be
      # run (debugging convenience)
      #
      # @option opts [String] :command the command to run, e.g. +ls -l+
      #
      # @option opts [String] :name the name of the command; if
      # missing, a name will be auto-generated from the command
      #
      # @option opts [String] :chdir change to this dir before running the command
      #
      # @option opts [String] :run_with An array of filters.  The filters are
      # applied to the command in reverse order.  A string filter is
      # simply prepended to the command.  A symbol is called as a method
      # on RunWith that accepts `(command, opts)` args and returns
      # `[new_command, new_opts]`.
      def initialize(opts)
        @opts = opts.dup

        self.env ||= {}
        self.run_with ||= []

        # name need not be unique here.  When added to a CommandSet,
        # within that set it may be assigned a unique name based off
        # this name.
        self.name ||= auto_name(command)

        @commandline = expand
      end

      def [](key)
        value = opts[key]
        if value.respond_to? :call
          value.call(self)
        else
          value
        end
      end

      # Set an option on this command.  The +value+ may be a Proc
      # object taking a single argument (or anything that responds to
      # +:call+), in which case the value on get (+#[]) will be the
      # result of that Proc called with +self+.
      def []=(key, value)
        opts[key] = value
      end

      def dir
        dir = self[:chdir] || '.'
        if self[:base_dir] && !Pathname.new(dir).absolute?
          File.join(self[:base_dir], dir)
        else
          dir
        end
      end

      def to_s
        commandline.sub(/^#{::Console::Mux::BUNDLE_EXEC_SH}/, '*bundle_exec.sh')
      end

      private
      
      # Apply any +:run_with+ options to generate the expanded
      # commandline that should be executed.
      def expand
        run_with.reverse.reduce(command) do |commandline, filter|
          if RunWith.respond_to?(filter)
            RunWith.send(filter, self, commandline)
          else
            "#{filter} #{commandline}"
          end
        end
      end
    end
  end
end