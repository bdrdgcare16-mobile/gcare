const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function addSimpleTasks() {
  console.log('📝 ADDING SIMPLE TASKS FOR EMPLOYEE');
  console.log('====================================');
  console.log('');

  try {
    // Find the specific employee (keshaw390@gmail.com)
    const employee = await prisma.user.findFirst({
      where: { email: 'keshaw390@gmail.com' }
    });

    if (!employee) {
      console.log('❌ Employee keshaw390@gmail.com not found');
      return;
    }

    console.log(`✅ Found employee: ${employee.name} (${employee.email}) - ID: ${employee.id}`);
    console.log('');

    // Clear existing tasks for this employee
    try {
      await prisma.task.deleteMany({
        where: { userId: employee.id }
      });
      console.log('🗑️ Cleared existing tasks for employee');
    } catch (error) {
      console.log('⚠️ No existing tasks to clear');
    }
    console.log('');

    // Add simple tasks without priority field
    const simpleTasks = [
      {
        userId: employee.id,
        title: 'District Program Review',
        description: 'Review and update district program documentation',
        status: 'PENDING',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Community Outreach Meeting',
        description: 'Prepare for community outreach program meeting',
        status: 'IN_PROGRESS',
        dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // 1 day
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Monthly Report Submission',
        description: 'Complete and submit monthly district report',
        status: 'COMPLETED',
        dueDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Field Visit Planning',
        description: 'Plan and schedule field visits for next week',
        status: 'PENDING',
        dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days
        assignedBy: 1
      }
    ];

    for (const taskData of simpleTasks) {
      const task = await prisma.task.create({
        data: taskData
      });
      console.log(`✅ Created task: ${task.title} (${task.status})`);
    }

    console.log('');
    console.log('🎉 Simple tasks added successfully!');
    console.log('');
    console.log('📋 Employee will now see these tasks in dashboard:');
    console.log('   - District Program Review (Pending)');
    console.log('   - Community Outreach Meeting (In Progress)');
    console.log('   - Monthly Report Submission (Completed)');
    console.log('   - Field Visit Planning (Pending)');
    console.log('');

  } catch (error) {
    console.error('❌ Error adding simple tasks:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addSimpleTasks(); 