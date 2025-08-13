const { spawn } = require('child_process');
const path = require('path');

console.log('🚀 Starting Production Server...');
console.log('================================');

// Start the backend server
const server = spawn('npm', ['start'], {
  cwd: __dirname,
  stdio: 'inherit',
  shell: true
});

server.on('error', (error) => {
  console.error('❌ Server Error:', error);
});

server.on('close', (code) => {
  console.log(`⚠️ Server closed with code ${code}`);
  console.log('🔄 Restarting in 5 seconds...');
  setTimeout(() => {
    console.log('🔄 Restarting server...');
    // Restart the server
    const newServer = spawn('npm', ['start'], {
      cwd: __dirname,
      stdio: 'inherit',
      shell: true
    });
  }, 5000);
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down gracefully...');
  server.kill('SIGINT');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down gracefully...');
  server.kill('SIGTERM');
  process.exit(0);
});

console.log('✅ Production server started successfully!');
console.log('📊 Health check: http://localhost:3000/health');
console.log('🔐 Auth endpoints: http://localhost:3000/auth');
console.log('🔌 WebSocket: ws://localhost:3000');
console.log('');
console.log('💡 Press Ctrl+C to stop the server'); 