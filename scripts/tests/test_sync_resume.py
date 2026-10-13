"""Real Git index checks: resume own work, preserve unrelated staging."""
from pathlib import Path
import subprocess
import tempfile

script = Path(__file__).resolve().parents[1] / 'publish-dotfiles.sh'
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    def git(*args, data=None):
        return subprocess.check_output(['git', *args], cwd=root, input=data, stderr=subprocess.PIPE)
    git('init', '-q', '-b', 'main')
    blob = git('hash-object', '-w', '--stdin', data=b'old\n').strip()
    tree = git('mktree', data=b'100644 blob '+blob+b'\tconfig\n').strip()
    commit = git('-c','user.name=Test','-c','user.email=test@example.invalid','commit-tree',tree.decode(),data=b'fixture\n').strip()
    git('update-ref','refs/heads/main',commit.decode())
    git('read-tree','--reset','-u','HEAD')
    (root/'config').write_text('new\n')
    def attempt():
        return subprocess.run(['/bin/bash','-c','source "$1"; stage_tracked_changes','test',str(script)],cwd=root,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode
    assert attempt() == 0
    assert attempt() == 0  # a previous failed signature leaves matching own index
    (root/'config').write_text('unrelated edit\n')
    git('add','config')
    before = git('write-tree')
    assert attempt() != 0
    assert git('write-tree') == before  # foreign staging survives intact
print('PASS: own staged retry, foreign index preservation')
