const { PrismaClient } = require('@prisma/client');

console.log('🧪 Testing PostgreSQL Connection and Operations...');

const POSTGRES_URL = 'postgresql://postgres:Nishali@localhost:5432/SERV';

async function testPostgreSQL() {
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: POSTGRES_URL,
      },
    },
  });

  try {
    console.log('📋 Step 1: Testing connection...');
    await prisma.$connect();
    console.log('✅ Connection successful');

    console.log('\n📋 Step 2: Testing basic queries...');
    
    // Test User table
    const userCount = await prisma.user.count();
    console.log(`✅ User table accessible - ${userCount} users found`);
    
    // Test Announcement table
    const announcementCount = await prisma.announcement.count();
    console.log(`✅ Announcement table accessible - ${announcementCount} announcements found`);
    
    // Test Task table
    const taskCount = await prisma.task.count();
    console.log(`✅ Task table accessible - ${taskCount} tasks found`);
    
    // Test Attendance table
    const attendanceCount = await prisma.attendance.count();
    console.log(`✅ Attendance table accessible - ${attendanceCount} attendance records found`);

    console.log('\n📋 Step 3: Testing relationships...');
    
    // Test user with relationships
    const userWithRelations = await prisma.user.findFirst({
      include: {
        attendance: true,
        tasks: true,
        notifications: true,
      },
    });
    
    if (userWithRelations) {
      console.log(`✅ User relationships working - User: ${userWithRelations.name}`);
      console.log(`   - Attendance records: ${userWithRelations.attendance.length}`);
      console.log(`   - Tasks: ${userWithRelations.tasks.length}`);
      console.log(`   - Notifications: ${userWithRelations.notifications.length}`);
    } else {
      console.log('⚠️  No users found to test relationships');
    }

    console.log('\n📋 Step 4: Testing complex queries...');
    
    // Test complex query with joins
    const recentAttendance = await prisma.attendance.findMany({
      take: 5,
      include: {
        user: {
          select: {
            name: true,
            email: true,
            department: true,
          },
        },
      },
      orderBy: {
        date: 'desc',
      },
    });
    
    console.log(`✅ Complex queries working - Found ${recentAttendance.length} recent attendance records`);

    console.log('\n📋 Step 5: Testing write operations...');
    
    // Test creating a test announcement
    const testAnnouncement = await prisma.announcement.create({
      data: {
        title: 'PostgreSQL Migration Test',
        content: 'This is a test announcement to verify PostgreSQL is working correctly.',
        priority: 'low',
        isPinned: false,
      },
    });
    
    console.log(`✅ Write operations working - Created announcement: ${testAnnouncement.title}`);
    
    // Clean up test data
    await prisma.announcement.delete({
      where: { id: testAnnouncement.id },
    });
    console.log('✅ Cleanup successful - Test announcement removed');

    console.log('\n🎉 All PostgreSQL tests passed successfully!');
    console.log('\n📊 Test Summary:');
    console.log('   ✅ Database connection');
    console.log('   ✅ Table access');
    console.log('   ✅ Relationship queries');
    console.log('   ✅ Complex queries');
    console.log('   ✅ Write operations');
    console.log('   ✅ Data cleanup');
    
    console.log('\n🚀 PostgreSQL is ready for production use!');

  } catch (error) {
    console.error('❌ Test failed:', error);
    console.log('\n🔧 Troubleshooting tips:');
    console.log('   1. Ensure PostgreSQL is running');
    console.log('   2. Check database credentials');
    console.log('   3. Verify database exists');
    console.log('   4. Run migrations: npm run migrate');
    throw error;
  } finally {
    await prisma.$disconnect();
    console.log('\n🔌 Database connection closed');
  }
}

testPostgreSQL()
  .then(() => {
    console.log('✅ Test script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Test script failed:', error);
    process.exit(1);
  }); 