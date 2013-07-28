#!/usr/bin/env ruby
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

require 'optparse'

require 'console/mux/console'

module Console
  module Mux
    include Log4r

    VERSION = File.read(File.expand_path('../../../VERSION', __FILE__), 16).strip

    BUNDLE_EXEC_SH = File.expand_path('bundle_exec.sh',
                                      File.join(__FILE__, '..', 'mux'))

    # @param [Array] args commandline arguments
    def self.run_argv(args = ARGV)
      options = {
        :init_file => nil
      }

      oparser = OptionParser.new do |opts|
        opts.banner = "Usage: console-mux <init_file>"
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
        opts.on('-f', '--init=FILE', 'Load this init file') do |file|
          options[:init_file] = file
        end
        opts.on('--version', 'Print the version and exit') do
          puts VERSION
          exit
        end
      end
      oparser.parse!(args)

      options[:init_file] ||= args.shift
      unless options[:init_file]
        $stderr.puts oparser
        exit 1
      end

      begin
        run(options)
      rescue Errno::ENOENT => e
        $stderr.puts e.message
        $stderr.puts e.backtrace.join("\n    ")
        exit 1
      end
    end

    def self.run(options)
      Console.new(options).startup
    end
  end
end
