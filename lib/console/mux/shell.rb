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
    # The interactive console is run within an instance of Shell.  All
    # instance methods are thus available as user commands.
    class Shell
      attr_reader :console

      class << self
        def delegate(obj_getter, method_syms)
          method_syms.each do |sym|
            send(:define_method, sym) do |*args, &block|
              obj = send(obj_getter)
              obj.send(sym, *args, &block)
            end
          end
        end

        def delegate_ok(obj_getter, method_syms)
          method_syms.each do |sym|
            send(:define_method, sym) do |*args, &block|
              obj = send(obj_getter)
              obj.send(sym, *args, &block)
              :ok
            end
          end
        end
      end

      def initialize(console)
        @console = console
      end

      def commands
        console.commands
      end

      delegate :console, [
                          :default_options
                         ]

      delegate_ok :console, [
                             :status,
                             :lastlog,
                             :run,
                             :add,
                             :start,
                             :stop,
                             :restart,
                             :reload,
                             :set_default_options,
                             :shutdown
                            ]

      # Yield the block with +hash+ merged into the default options.
      # The options are restored.
      def with_defaults(hash={})
        orig_options = default_options
        set_default_options(default_options.merge(hash))
        begin
          yield
        ensure
          set_default_options(orig_options)
        end
      end
    end
  end
end
