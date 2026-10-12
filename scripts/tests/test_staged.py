"""Run with python3: verify secret-boundary checks without real secret values."""
import sys
sys.dont_write_bytecode = True
import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location('scan', Path(__file__).resolve().parents[1] / 'check-staged.py')
scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan)
scan.check('dot_codex/AGENTS.md', b'ordinary preferences')
scan.check('encrypted_private_dot_secret.age', b'age-encryption.org/v1\nfixture')
for path, data in [('.env.test', b'fixture'), ('private_dot_config/credentials', b'fixture'), ('encrypted_private_dot_secret.age', b'plaintext fixture'), ('dot_example', b'-----BEGIN ' + b'OPENSSH ' + b'PRIVATE KEY-----'), ('dot_codex/private_hooks.json', b'invalid JSON')]:
    try:
        scan.check(path, data)
    except ValueError:
        pass
    else:
        raise AssertionError('Failed to reject ' + path)
print('PASS: secret filenames, private keys, encrypted headers, hook JSON')
