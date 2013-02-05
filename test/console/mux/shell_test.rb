#
# Copyright (C) 2013 Common Ground Publishing
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
  class ShellTest < MiniTest::Unit::TestCase
    def setup
      @console = Console.new
      @shell = Shell.new(@console)
    end

    def test_with_defaults_nesting
      @shell.with_defaults(:key => 'original') do
        @shell.add(:command => 'a')
        @shell.add(:key => 'modified', :command => 'b')
        @shell.with_defaults(:key => 'modified') do
          @shell.add(:command => 'c')
        end
        @shell.add(:command => 'd')
      end

      assert @shell.commands['a']
      assert @shell.commands['b']
      assert @shell.commands['c']
      assert @shell.commands['d']

      assert_equal 'original', @shell.commands['a'].opts[:key]
      assert_equal 'modified', @shell.commands['b'].opts[:key]
      assert_equal 'modified', @shell.commands['c'].opts[:key]
      assert_equal 'original', @shell.commands['d'].opts[:key]
    end

    def test_with_defaults_env_nesting
      @shell.with_defaults(:env => {'TEST_KEY' => 'value'}) do
        @shell.add(:command => 'a')
        @shell.add(:env => {'ANOTHER_KEY' => 'value'}, :command => 'b')
        @shell.add(:command => 'c')
      end

      assert @shell.commands['a']
      assert @shell.commands['b']
      assert @shell.commands['c']

      expected = { 'TEST_KEY' => 'value' }
      expected2 = { 'ANOTHER_KEY' => 'value' }

      assert_equal expected, @shell.commands['a'].env
      assert_equal expected2, @shell.commands['b'].env
      assert_equal expected, @shell.commands['c'].env
    end

    def test_with_defaults_env_nesting_run_with
      @shell.with_defaults(:run_with => [:rbenv], :ruby => 'default', :env => {'TEST_KEY' => 'value'}) do
        @shell.add(:command => 'a')
        @shell.add(:ruby => 'other', :command => 'b')
        @shell.add(:command => 'c')
      end

      assert @shell.commands['a']
      assert @shell.commands['b']
      assert @shell.commands['c']

      assert_equal 'default', @shell.commands['a'].env['RBENV_VERSION']
      assert_equal   'other', @shell.commands['b'].env['RBENV_VERSION']
      assert_equal 'default', @shell.commands['c'].env['RBENV_VERSION']
    end
  end
end
