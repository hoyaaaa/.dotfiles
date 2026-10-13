"""Run with python3: verifies capture, encryption exclusion and failure state."""
import json
import os
from pathlib import Path
import shutil
import signal
import time
import subprocess
import tempfile

script = Path(__file__).resolve().parents[1] / 'codex-sync.sh'
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    repo = home / '.dotfiles'
    (repo / 'bin').mkdir(parents=True)
    (repo / 'scripts').mkdir()
    shutil.copy2(script, repo / 'scripts/codex-sync.sh')
    shutil.copy2(script.parent / 'with-sync-lock.py', repo / 'scripts/with-sync-lock.py')
    (repo / 'dot_example').write_text('old\n')
    (home / '.example').write_text('new\n')
    # Invalid encrypted content must never be decrypted by a local snapshot.
    encrypted = repo / 'encrypted_private_dot_secret.age'
    encrypted.write_text('not an age ciphertext\n')
    (home / '.secret').write_text('private fixture\n')
    config = home / 'config'
    (config / 'chezmoi').mkdir(parents=True)
    (config / 'chezmoi/chezmoi.toml').write_text(f'sourceDir = "{repo}"\n')
    helper = repo / 'bin/dotfiles'
    helper.write_text('#!/bin/bash\nprintf "%s\\n" "$1" >>"$HOME/calls"\n')
    helper.chmod(0o755)
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config), XDG_STATE_HOME=str(home / 'state'))
    run = subprocess.run(['/bin/bash', str(repo / 'scripts/codex-sync.sh')], env=env)
    assert run.returncode == 0
    assert (repo / 'dot_example').read_text() == 'new\n'
    assert encrypted.read_text() == 'not an age ciphertext\n'
    assert (home / 'calls').read_text().splitlines() == ['packages-snapshot', 'apps-snapshot']
    state = home / 'state/dotfiles/snapshot-state.json'
    assert json.loads(state.read_text())['status'] == 'completed'
    assert not (state.parent / 'snapshot.lock').exists()
    helper.write_text('#!/bin/bash\nexit 7\n')
    run = subprocess.run(['/bin/bash', str(repo / 'scripts/codex-sync.sh')], env=env)
    assert run.returncode == 7
    assert json.loads(state.read_text())['status'] == 'failed'
    assert not (state.parent / 'snapshot.lock').exists()
    holder = subprocess.Popen(['python3', str(repo / 'scripts/with-sync-lock.py'), '-c', 'echo ready; exec sleep 60'], env=env, stdout=subprocess.PIPE, start_new_session=True)
    assert holder.stdout.readline().strip() == b'ready'
    busy = subprocess.run(['/bin/bash', str(repo / 'scripts/codex-sync.sh')], env=env)
    assert busy.returncode == 0  # busy lock skips the failing helper
    os.killpg(holder.pid, signal.SIGKILL)
    holder.wait(timeout=5)
    recovered = subprocess.run(['/bin/bash', str(repo / 'scripts/codex-sync.sh')], env=env)
    assert recovered.returncode == 7  # interrupted owner released the kernel lock
print('PASS: live capture, encrypted exclusion, inventories, failure state, interrupted-lock recovery')
