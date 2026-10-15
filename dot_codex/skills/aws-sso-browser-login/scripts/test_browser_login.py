"""Offline checks; never opens a browser or starts AWS authentication."""
import contextlib
import io
import json
import sys
import unittest
from unittest.mock import Mock, patch
import aws_sso_browser_login as login


class BrowserLoginTest(unittest.TestCase):
    def test_explicit_profile_is_one_argument(self):
        command = json.dumps([sys.executable, '--profile={profile}', '{url}'])
        self.assertEqual(login.browser_argv(command, '업무 $(echo unsafe)')[1],
                         '--profile=업무 $(echo unsafe)')
        for bad in ('null', '[]', '["echo", "{url}"]', '["echo", "{profile}"]'):
            with self.assertRaises(ValueError):
                login.browser_argv(bad, '업무')

    def test_login_routes_url_without_logging_secrets(self):
        process = Mock(stdout=iter(['Code SECRET-CODE\n', 'https://example.test/auth?token=SECRET\n']))
        process.wait.return_value = 0
        process.poll.return_value = 0
        output = io.StringIO()
        with patch.object(login.subprocess, 'Popen', side_effect=[process, Mock()]) as launch:
            with contextlib.redirect_stdout(output):
                self.assertEqual(login.run('aws-test', ['browser', '--profile=work', '{url}']), 0)
        self.assertEqual(launch.call_args_list[1].args[0],
                         ['browser', '--profile=work', 'https://example.test/auth?token=SECRET'])
        self.assertNotIn('SECRET', output.getvalue())

    def test_failed_launch_cleans_up_login(self):
        process = Mock(stdout=iter(['https://example.test/auth\n']))
        process.poll.return_value = None
        with patch.object(login.subprocess, 'Popen', side_effect=[process, OSError('launch failed')]):
            with self.assertRaises(OSError):
                login.run('aws-test', ['browser', '{url}'])
        process.terminate.assert_called_once()
        process.wait.assert_called_once_with(timeout=5)


if __name__ == '__main__':
    unittest.main()
