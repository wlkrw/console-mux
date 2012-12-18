#!/bin/sh
#
# bundle_exec.sh - emulate 'bundle exec' but with a shell script
# rather than a ruby script.  Modifies the environment just like
# bundle exec would.
#
# Running "bundle exec ruby" starts a ruby in which then execs the
# command, 'ruby'.  In JRuby 1.6, the command is started in a child
# process.  When using a Foreman-like tool that has the ability to
# kill and/or restart such a command, only the parent will be killed
# while the child ruby continues on.  This bundle_exec.sh wokrs
# similarly to bundle exec, but the exec is done in the shell rather
# than in JRuby to avoid the difficult-to-kill child process.
#
# For bourne-compatible shells.
#
# Author: Patrick Mahoney <pat@polycrystal.org>

# Run 'bundle exec' in a subshell; echo a string that when eval'ed
# will duplicate the 'bundle exec' environment.
env=$(bundle exec sh -c \
     'echo "export BUNDLE_BIN_PATH=\"$BUNDLE_BIN_PATH\"; \
            export PATH=\"$PATH\"; \
            export BUNDLE_GEMFILE=\"$BUNDLE_GEMFILE\"; \
            export RUBYOPT=\"$RUBYOPT\"";')

ret="$?"
if [ "$ret" = 0 ]; then
  # Bring bundle exec environment into the current shell.
  eval $env
  exec "$@"
else
  echo "$env"
  exit "$ret"
fi
