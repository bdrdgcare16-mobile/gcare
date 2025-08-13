const fs = require('fs');
const path = require('path');

// Files to fix
const files = [
  'src/routes/leave.ts',
  'src/routes/checkin.ts', 
  'src/routes/task.ts',
  'src/routes/notifications.ts'
];

function fixTypeScriptErrors(filePath) {
  console.log(`🔧 Fixing TypeScript errors in ${filePath}...`);
  
  const fullPath = path.join(__dirname, filePath);
  let content = fs.readFileSync(fullPath, 'utf8');
  
  // Replace error?.message with proper type casting
  const originalPattern = /error\?\.message \|\| 'Internal server error'/g;
  const replacement = "(error as any)?.message || 'Internal server error'";
  
  const newContent = content.replace(originalPattern, replacement);
  
  if (content !== newContent) {
    fs.writeFileSync(fullPath, newContent);
    console.log(`✅ Fixed ${filePath}`);
  } else {
    console.log(`ℹ️  No changes needed for ${filePath}`);
  }
}

console.log('🔧 FIXING TYPESCRIPT ERRORS');
console.log('===========================');
console.log('');

files.forEach(fixTypeScriptErrors);

console.log('');
console.log('✅ All TypeScript errors fixed!');
console.log('💡 Now try starting the backend server'); 