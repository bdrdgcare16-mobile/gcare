const { spawn } = require('child_process');

console.log('🚀 Starting backend server...');
console.log('=============================');
console.log('');

const server = spawn('npx', ['ts-node', 'src/index.ts'], {
  stdio: 'inherit',
  shell: true
});

server.on('error', (error) => {
  console.error('❌ Failed to start server:', error.message);
});

server.on('close', (code) => {
  console.log(`\n💡 Server process exited with code ${code}`);
  if (code !== 0) {
    console.log('❌ Server failed to start properly');
  }
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n🛑 Stopping server...');
  server.kill('SIGINT');
  process.exit(0);
}); 