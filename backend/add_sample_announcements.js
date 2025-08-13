const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const sampleAnnouncements = [
  {
    title: '🎉 Welcome to Employee Management System',
    content: 'Welcome to our new Employee Management System! This platform will help streamline our daily operations and improve communication across the organization.',
    priority: 'high',
    isPinned: true,
  },
  {
    title: '📅 Holiday Notice - Independence Day',
    content: 'Office will be closed on August 15th for Independence Day. All employees are requested to plan their work accordingly.',
    priority: 'high',
    isPinned: false,
  },
  {
    title: '📋 New Attendance Policy Update',
    content: 'A new attendance policy will be effective from next month. Please review the updated guidelines in the employee handbook.',
    priority: 'medium',
    isPinned: true,
  },
  {
    title: '🎯 Team Building Event - Next Week',
    content: 'We are organizing a team building event next week. All employees are encouraged to participate. More details will be shared soon.',
    priority: 'medium',
    isPinned: false,
  },
  {
    title: '☕ Coffee Break Schedule',
    content: 'Coffee breaks are scheduled at 10:30 AM and 3:30 PM. Please maintain social distancing during breaks.',
    priority: 'low',
    isPinned: false,
  },
  {
    title: '💻 IT Maintenance Notice',
    content: 'Scheduled IT maintenance will be conducted this weekend. Some systems may be temporarily unavailable.',
    priority: 'medium',
    isPinned: false,
  },
];

async function addSampleAnnouncements() {
  try {
    console.log('🚀 Adding sample announcements to database...');
    
    // Clear existing announcements
    await prisma.announcement.deleteMany({});
    console.log('✅ Cleared existing announcements');
    
    // Add new announcements
    for (const announcement of sampleAnnouncements) {
      await prisma.announcement.create({
        data: {
          title: announcement.title,
          content: announcement.content,
          priority: announcement.priority,
          isPinned: announcement.isPinned,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });
    }
    
    console.log('✅ Successfully added', sampleAnnouncements.length, 'announcements');
    
    // Display added announcements
    const allAnnouncements = await prisma.announcement.findMany({
      orderBy: { createdAt: 'desc' }
    });
    
    console.log('\n📢 Current Announcements:');
    allAnnouncements.forEach((announcement, index) => {
      console.log(`${index + 1}. ${announcement.title}`);
      console.log(`   Priority: ${announcement.priority.toUpperCase()}`);
      console.log(`   Pinned: ${announcement.isPinned ? 'Yes' : 'No'}`);
      console.log(`   Date: ${announcement.createdAt.toDateString()}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error adding announcements:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the script
addSampleAnnouncements(); 