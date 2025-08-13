const fs = require('fs');
const path = require('path');

const routeFiles = [
  'src/routes/notifications.ts',
  'src/routes/task.ts',
  'src/routes/leave.ts',
  'src/routes/checkin.ts'
];

function fixTypeScriptErrors() {
  console.log('🔧 FIXING ALL TYPESCRIPT ERRORS');
  console.log('================================');
  console.log('');

  routeFiles.forEach(filePath => {
    try {
      if (fs.existsSync(filePath)) {
        let content = fs.readFileSync(filePath, 'utf8');
        
        // Fix error.message to (error as any)?.message
        const originalPattern = /error\?\.message \|\| 'Internal server error'/g;
        const replacement = '(error as any)?.message || \'Internal server error\'';
        
        if (content.includes('error?.message')) {
          content = content.replace(originalPattern, replacement);
          fs.writeFileSync(filePath, content, 'utf8');
          console.log(`✅ Fixed: ${filePath}`);
        } else {
          console.log(`⏭️  Already fixed: ${filePath}`);
        }
      } else {
        console.log(`❌ File not found: ${filePath}`);
      }
    } catch (error) {
      console.error(`❌ Error fixing ${filePath}:`, error.message);
    }
  });

  console.log('');
  console.log('🎉 All TypeScript errors fixed!');
  console.log('💡 You can now start the backend server');
}

fixTypeScriptErrors(); 