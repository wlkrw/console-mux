console-mux
===========

A tool inspired by [Foreman](https://github.com/ddollar/foreman) for
multiplexing the output of several services into a single console.

    $ gem install console-mux
    $ cat processes.rb
    run(:command => 'rails s', :chdir => 'app1')
    run(:command => 'rails s',
        :run_with => [:rvm_shell, :bundle_exec],
        :ruby => 'ruby-1.9.3',
        :chdir => 'app2')

    $ console-mux -f processes.rb

The two Rails apps will be started in parallel in two separate
processes.  They can use individual RVM or rbenv rubies.

The console output from both apps will be multiplexed (interleaved
line by line) into a single console.

Shell
-----

A limited shell is available to control running processes.  This is a
Ruby shell (provided by [Ripl](https://github.com/cldwalker/ripl)),
and so accepts Ruby syntax.

* `status` Print the status of running commands

* `lastlog <string or regex>` Scan through the output buffer to print
   lines matching the given pattern

* `start <command>` Start the named command

* `stop <command>` Stop the named command

* `restart <command>` Stop and then restart the named command

* `exit` (or `quit`, `^D`) Attempt to stop all commands by first
   interrupting each command (`^C`) and finally forcibly terminating
   after a timeout

Advanced `run` usage
--------------------

The `run` command accepts one or more command hashes.

If multiple command options are given, they will be run sequentially
one-at-a-time.  Only the final command will remain in the active
command list; the others will be removed as they complete and exit.

If an array of command options is given, they will be run in parallel,
even if part of sequential sequence.  Thus you can specify `run(c1,
c2, [c3,c4,c5], c6)` which will run commands 1 and 2 sequentially,
then 3, 4 and 5 in parallel, then finally command 6 only after all
previous commands complete.

    run({:command => 'ls'},
       [{:command => 'ls'}, {:command => 'ls'}],
        {:command => 'ls'})

