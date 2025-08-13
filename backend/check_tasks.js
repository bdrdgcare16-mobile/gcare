const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkTasks() {
  console.log('📋 CHECKING TASKS IN DATABASE');
  console.log('=============================');
  console.log('');

  try {
    // Get all tasks
    const tasks = await prisma.task.findMany({
      include: {
        user: {
          select: {
            name: true,
            email: true
          }
        }
      }
    });

    console.log(`📊 Total tasks in database: ${tasks.length}`);
    console.log('');

    if (tasks.length === 0) {
      console.log('❌ No tasks found in database');
      console.log('💡 Run ADD_SAMPLE_TASKS.bat to add sample tasks');
    } else {
      console.log('📋 Tasks in database:');
      console.log('=====================');
      
      tasks.forEach((task, index) => {
        console.log(`${index + 1}. ${task.title}`);
        console.log(`   Status: ${task.status}`);
        console.log(`   Assigned to: ${task.user.name} (${task.user.email})`);
        console.log(`   Due: ${task.dueDate ? task.dueDate.toDateString() : 'No due date'}`);
        console.log('');
      });
    }

    // Get employee users
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      select: { id: true, name: true, email: true }
    });

    console.log('👥 Employee users:');
    console.log('==================');
    employees.forEach((emp, index) => {
      console.log(`${index + 1}. ${emp.name} (${emp.email}) - ID: ${emp.id}`);
    });

  } catch (error) {
    console.error('❌ Error checking tasks:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkTasks(); 