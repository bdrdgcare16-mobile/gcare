const fs = require('fs');
const path = require('path');

// Files to fix
const files = [
  'src/routes/task.ts',
  'src/routes/leave.ts',
  'src/routes/checkin.ts'
];

function fixErrorHandling(filePath) {
  console.log(`🔧 Fixing error handling in ${filePath}...`);
  
  const fullPath = path.join(__dirname, filePath);
  let content = fs.readFileSync(fullPath, 'utf8');
  
  // Replace all instances of error.message with proper error handling
  const originalPattern = /res\.status\(500\)\.json\(\{ success: false, error: error\.message \}\);/g;
  const replacement = (match) => {
    // Extract the context to create a meaningful error message
    const lines = content.split('\n');
    const lineIndex = content.indexOf(match);
    const lineNumber = content.substring(0, lineIndex).split('\n').length;
    
    // Find the function name or route context
    let context = 'Unknown operation';
    for (let i = lineNumber - 1; i >= 0; i--) {
      const line = lines[i];
      if (line.includes('router.') && (line.includes('get') || line.includes('post') || line.includes('put') || line.includes('delete'))) {
        const routeMatch = line.match(/router\.(get|post|put|delete)\s*\(\s*['"`]([^'"`]+)['"`]/);
        if (routeMatch) {
          context = `${routeMatch[1].toUpperCase()} ${routeMatch[2]}`;
          break;
        }
      }
    }
    
    return `console.error('${context} error:', error);\n    res.status(500).json({ success: false, error: error?.message || 'Internal server error' });`;
  };
  
  const newContent = content.replace(originalPattern, replacement);
  
  if (content !== newContent) {
    fs.writeFileSync(fullPath, newContent);
    console.log(`✅ Fixed ${filePath}`);
  } else {
    console.log(`ℹ️  No changes needed for ${filePath}`);
  }
}

console.log('🔧 FIXING ERROR HANDLING IN BACKEND ROUTES');
console.log('==========================================');
console.log('');

files.forEach(fixErrorHandling);

console.log('');
console.log('✅ All error handling fixed!');
console.log('💡 Now try starting the backend server again'); 