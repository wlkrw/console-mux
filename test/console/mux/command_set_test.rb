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
require 'test_helper'

module Console::Mux
  class TestCommandSet < MiniTest::Unit::TestCase
    def setup
      @commands = CommandSet.new
    end

    def test_pretty_seconds
      assert_equal '1 s', @commands.pretty_seconds(1)
      assert_equal '2 s', @commands.pretty_seconds(2)
      assert_equal '10 s', @commands.pretty_seconds(10)
      assert_equal '1 min', @commands.pretty_seconds(100)
      assert_equal '1 min', @commands.pretty_seconds(119)
      assert_equal '2 min', @commands.pretty_seconds(120)
      assert_equal '2 min', @commands.pretty_seconds(121)
      assert_equal '16 min', @commands.pretty_seconds(1000)
      assert_equal '2 hr', @commands.pretty_seconds(10000)
      assert_equal '1.2 days', @commands.pretty_seconds(100000)
    end
  end
end