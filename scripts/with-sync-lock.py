#!/usr/bin/env python3
"""Hold a kernel lock through exec; interrupted sessions cannot leave it held."""
import fcntl
import os
from pathlib import Path
import sys

state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'dotfiles'
state.mkdir(parents=True, exist_ok=True)
lock = (state / 'snapshot.lockfile').open('a')
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit(0)
os.set_inheritable(lock.fileno(), True)
env = dict(os.environ, DOTFILES_SYNC_LOCKED=str(os.getpid()))
os.execvpe('/bin/bash', ['/bin/bash', *sys.argv[1:]], env)
