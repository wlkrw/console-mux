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

class String
  # DJB hash algorithm 2.  The default Ruby string hash is not stable
  # across Ruby invocations (for security reasons).
  def hash_djb2
    hash = 5381
    each_codepoint do |c|
      hash = ((hash << 5) + hash) + c # equiv. hash * 33 + c?
    end
    hash
  end
end

module Console

  module Mux

    class ColorFormatter < Log4r::BasicFormatter
      BASIC_COLORS = {
        :black => 0,
        :red => 1,
        :green => 2,
        :yellow => 3,
        :blue => 4,
        :magenta => 5,
        :cyan => 6,
        :grey => 7,
      }

      # On 256 color term, many colors beyond 127 seem to be
      # unreadably light.  Of course, if your terminal has a dark
      # background that may be preferable.
      N_COLORS = [127, `tput colors`.to_i].min

      COLOR_STRINGS = []
      N_COLORS.times do |i|
        COLOR_STRINGS[i] = `tput setaf #{i}`
      end

      RESET_COLORS = `tput sgr0`      # last string is reset

      MAX_WIDTH = 35
      MIN_WIDTH = 8

      attr_accessor :label_width

      def initialize(hash={})
        super(hash)
        @label_width = MIN_WIDTH
        @colors = Hash.new
      end

      def format(event)
        self.label_width = [[self.label_width, event.name.size].max, MAX_WIDTH].min

        color, name = case event.name
               when 'process'
                 [:red, '-' * label_width]
               else
                 [color_for(event.name), event.name]
               end

        "%s%-#{label_width}s|%s %s" %
          [set_color_str(color), name, unset_color_str, event.data]
      end

      protected

      def color_for(name)
        @colors[name] ||= name.hash_djb2 % N_COLORS
      end

      def set_color_str(color)
        c = if color.kind_of? Symbol
              BASIC_COLORS[color]
            else
              color
            end
        COLOR_STRINGS[c]
      end

      def unset_color_str
        RESET_COLORS
      end
    end

  end

end