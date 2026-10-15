# Verified Ego Lite login and cleanup

Verified on 2026-10-15 with the `회사용` profile: AWS SSO login exited 0, STS identity succeeded, `finish({ keep: [] })` completed, and `listTaskSpaces()` no longer contained the login space. The existing browser session completed authentication without a manual approval click. Manual approval, password/OTP handoff, and failed-authentication cleanup were not exercised.

Run through a shell heredoc, not a saved JavaScript file. Keep the shell session alive so the child AWS process and its URL stay in memory. Use short tool yields and resume the returned command session. If approval requires interaction, use another ego-browser invocation against the printed space ID; follow ego-lite handoff rules for user-only actions. Do not print snapshots containing authorization URLs, codes, or secrets.

```bash
ego-browser nodejs <<'JS'
const { spawn, execFile } = await import('node:child_process');
const profile = process.env.AWS_DEFAULT_PROFILE;
if (!profile) throw new Error('AWS_DEFAULT_PROFILE must be set');
const matches = (await profiles()).filter(p => p.name === '회사용');
if (matches.length !== 1) throw new Error('Company profile missing or ambiguous');
const task = await taskSpace('AWS SSO login', { profileId: matches[0].id });
console.log({ spaceId: task.spaceId, profile: matches[0].name });
const child = spawn('aws', ['sso', 'login', '--profile', profile, '--no-browser'],
  { stdio: ['ignore', 'pipe', 'pipe'] });
const completed = new Promise((resolve, reject) => {
  child.once('error', () => reject(new Error('Cannot start AWS CLI')));
  child.once('close', resolve);
});
// Attach a rejection handler immediately, including during navigation.
completed.catch(() => {});
let buffer = '', routed = false;
await new Promise((resolve, reject) => {
  const capture = async chunk => {
    buffer += chunk.toString();
    const match = buffer.match(/https:\/\/[^\s"'<>]+/);
    if (!match || routed) return;
    routed = true;
    try {
      await task.page('p1').goto(match[0]);
      buffer = '';
      console.log({ authorizationPageOpened: true, spaceId: task.spaceId });
      resolve();
    } catch {
      reject(new Error('SSO navigation failed; preserve space and inspect login process'));
    }
  };
  child.stdout.on('data', capture);
  child.stderr.on('data', capture);
  child.once('error', () => reject(new Error('Cannot start AWS CLI')));
  child.once('close', code => {
    if (!routed) reject(new Error('AWS exited before authorization URL; exit ' + code));
  });
});
const status = await completed;
console.log({ ssoExitCode: status });
if (status !== 0) throw new Error('SSO failed; preserving TaskSpace');
await new Promise((resolve, reject) => {
  execFile('aws', ['sts', 'get-caller-identity', '--profile', profile, '--output', 'json'],
    (error, stdout) => {
      if (error) return reject(new Error('STS identity verification failed'));
      try {
        const identity = JSON.parse(stdout);
        if (!identity.Account || !identity.Arn) throw new Error();
        console.log({ identityVerified: true });
        resolve();
      } catch { reject(new Error('Invalid STS identity response')); }
    });
});
await task.finish({ keep: [] });
console.log({ cleanupCompleted: true, spaceId: task.spaceId });
JS
```

After the command completes, make one separate `ego-browser nodejs` call to `listTaskSpaces()` and check that the printed ID is absent (compare `spaceId` or `id` as returned). Report authentication and cleanup separately if either fails. Never call `finish()` again as a verification step, switch profiles on failure, or claim this workflow quits the entire browser application.
