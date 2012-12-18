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
require "log4r/outputter/outputter"
require "log4r/staticlogger"

module Console

  module Mux
    
    ##
    # IO Outputter invokes print then flush on the wrapped IO
    # object. If the IO stream dies, IOOutputter sets itself to OFF
    # and the system continues on its merry way.
    #
    # To find out why an IO stream died, create a logger named 'log4r'
    # and look at the output.

    class ConsoleOutputter < Log4r::Outputter

      def initialize(_name, console, hash={})
        @console = console
        super(_name, hash)
      end

      private

      # perform the write (copied from Log4r::IOOutputter but uses console.puts)
      def write(data)
        begin
          @console.puts data
        rescue => e # recover from this instead of crash
          Log4r::Logger.log_internal {"IOError in Outputter '#{@name}'!"}
          Log4r::Logger.log_internal {e}
          raise e
        end
      end

    end

  end

end