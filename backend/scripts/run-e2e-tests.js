const { spawn } = require('child_process');
const path = require('path');

const backendDir = path.resolve(__dirname, '..');
const flutterTestTarget = process.argv.slice(2)[0] ?? 'all';

const env = {
  ...process.env,
  FLUTTER_TEST_TARGET: flutterTestTarget,
};

const firebaseProcess = spawn(
  'firebase',
  ['emulators:start', '--only', 'auth,functions,firestore'],
  {
    cwd: backendDir,
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true,
    env,
  }
);

let flutterStarted = false;

const startFlutterTests = () => {
  if (flutterStarted) return;
  flutterStarted = true;

  const flutterProcess = spawn(process.execPath, [path.join(__dirname, 'run-flutter-tests.js')], {
    cwd: backendDir,
    stdio: 'inherit',
    env,
  });

  flutterProcess.on('exit', (code) => {
    firebaseProcess.kill('SIGINT');
    process.exit(code ?? 1);
  });
};

firebaseProcess.stdout.on('data', (chunk) => {
  process.stdout.write(chunk);
  if (String(chunk).includes('All emulators ready!')) {
    startFlutterTests();
  }
});

firebaseProcess.stderr.on('data', (chunk) => {
  process.stderr.write(chunk);
});

firebaseProcess.on('exit', (code) => {
  if (!flutterStarted) {
    process.exit(code ?? 1);
  }
});

process.on('SIGINT', () => {
  firebaseProcess.kill('SIGINT');
  process.exit(130);
});
