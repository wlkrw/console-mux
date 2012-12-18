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
module Console
  module Mux
    class RunWith
      class << self
        # A filter for running a command with RVM shell.  Looks at the
        # :ruby option.
        #
        # @param [Command] c
        # @param [String] str the command string
        def rvm_shell(c, str)
          rvm_command = 'rvm-shell '
          rvm_command += "'#{c[:ruby]}' " if c[:ruby]
          rvm_command += "-c '#{str}'"
          rvm_command
        end

        # A filter for running a command with rbenv. Sets RBENV_VERSION
        # environment var will be set to the value of the :ruby
        # option.
        #
        # @param [Command] c
        # @param [String] str the command string
        def rbenv(c, str)
          c.env['RBENV_VERSION'] = c[:ruby]

          # Strip out any rbenv version bin path.  Assumes rbenv is
          # installed in .rbenv.  This is necessary because if we run
          # console-mux via an rbenv shim, that shim first tacks on
          # the bin path to the in-use ruby version prior to exec'ing
          # the actual console-mux...  But we don't want that path to
          # follow down to sub processes spawned by console-mux.
          c.env['PATH'] =
            ENV['PATH'].
            split(File::PATH_SEPARATOR).
            reject{|p| p =~ %r{.rbenv/versions}}.
            join(File::PATH_SEPARATOR)
          
          str
        end

        # A filter for running a command with bundle exec.  Ensures
        # the BUNDLE_GEMFILE environment variable is cleared before
        # running bundle exec.
        def bundle_exec(c, str)
          "bundle exec #{str}"
        end

        def bundle_exec_sh(c, str)
          "#{::Console::Mux::BUNDLE_EXEC_SH} #{str}"
        end
      end
    end
  end
end