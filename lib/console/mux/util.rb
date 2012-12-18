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
require 'console/mux/object_compose'

module Console
  module Mux
    module Util
      # Fetch the first word from a string of space-separated words.
      def first_word(str)
        str.split[0]
      end

      # Return +str+ with the last file extension (.something)
      # removed.
      def chop_file_extension(str)
        if str =~ /(.*)\.\w+$/
          $1
        else
          str
        end
      end

      # File.basename
      def basename(str)
        File.basename(str)
      end

      # Strip any file extension from the file basename from the first
      # word of +str+.
      def auto_name(str)
        compose([:first_word,
                 :basename,
                 :chop_file_extension],
                str)
      end
    end
  end
end