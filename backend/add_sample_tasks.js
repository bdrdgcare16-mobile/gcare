const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function addSampleTasks() {
  console.log('📝 ADDING SAMPLE TASKS FOR EMPLOYEE');
  console.log('===================================');
  console.log('');

  try {
    // Find the employee user
    const employee = await prisma.user.findFirst({
      where: { role: 'EMPLOYEE' }
    });

    if (!employee) {
      console.log('❌ No employee found in database');
      return;
    }

    console.log(`✅ Found employee: ${employee.name} (${employee.email})`);
    console.log('');

    // Add sample tasks
    const sampleTasks = [
      {
        userId: employee.id,
        title: 'Complete Project Documentation',
        description: 'Update and finalize project documentation for Q1 review',
        status: 'PENDING',
        priority: 'MEDIUM',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Client Meeting Preparation',
        description: 'Prepare presentation materials for upcoming client meeting',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Team Collaboration Review',
        description: 'Review and provide feedback on team collaboration processes',
        status: 'COMPLETED',
        priority: 'LOW',
        dueDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        assignedBy: 1
      },
      {
        userId: employee.id,
        title: 'Database Optimization',
        description: 'Analyze and optimize database performance for better efficiency',
        status: 'PENDING',
        priority: 'MEDIUM',
        dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
        assignedBy: 1
      }
    ];

    for (const taskData of sampleTasks) {
      const task = await prisma.task.create({
        data: taskData
      });
      console.log(`✅ Created task: ${task.title} (${task.status})`);
    }

    console.log('');
    console.log('🎉 Sample tasks added successfully!');
    console.log('');
    console.log('📋 Employee can now see these tasks in their dashboard:');
    console.log('   - Complete Project Documentation (Pending)');
    console.log('   - Client Meeting Preparation (In Progress)');
    console.log('   - Team Collaboration Review (Completed)');
    console.log('   - Database Optimization (Pending)');
    console.log('');

  } catch (error) {
    console.error('❌ Error adding sample tasks:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addSampleTasks(); 