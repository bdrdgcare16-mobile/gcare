const { spawn } = require('child_process');

console.log('🚀 Starting Stable Backend Server...');
console.log('====================================');

// Function to start server
function startServer() {
  console.log('🔄 Starting server...');
  
  const server = spawn('npx', ['ts-node', 'src/index.ts'], {
    cwd: __dirname,
    stdio: 'inherit',
    shell: true
  });

  server.on('error', (error) => {
    console.error('❌ Server Error:', error);
    console.log('🔄 Restarting in 3 seconds...');
    setTimeout(startServer, 3000);
  });

  server.on('close', (code) => {
    console.log(`⚠️ Server closed with code ${code}`);
    console.log('🔄 Restarting in 3 seconds...');
    setTimeout(startServer, 3000);
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
}

// Start the server
startServer();

console.log('✅ Stable server startup initiated!');
console.log('📊 Health check: http://localhost:3000/health');
console.log('🔐 Auth endpoints: http://localhost:3000/auth');
console.log('🔌 WebSocket: ws://localhost:3000');
console.log('');
console.log('💡 Press Ctrl+C to stop the server'); 