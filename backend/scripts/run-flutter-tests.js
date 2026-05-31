const { spawn } = require('child_process');
const path = require('path');

const appDir = path.resolve(__dirname, '..', '..', 'mescla_invest');
const target = process.env.FLUTTER_TEST_TARGET;
const flutterArgs = target && target !== 'all' ? ['test', target] : ['test'];

const child = spawn('flutter', flutterArgs, {
  cwd: appDir,
  stdio: 'inherit',
  shell: true,
});

child.on('exit', (code) => {
  process.exit(code ?? 1);
});
