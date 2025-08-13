const { PrismaClient } = require('@prisma/client');
const { execSync } = require('child_process');
const path = require('path');

console.log('🚀 Setting up PostgreSQL for Nishali HRMS...');

const POSTGRES_URL = 'postgresql://postgres:Nishali@localhost:5432/SERV';

async function setupPostgreSQL() {
  try {
    console.log('📋 Step 1: Installing PostgreSQL dependencies...');
    
    // Install PostgreSQL dependencies
    try {
      execSync('npm install pg @types/pg', { stdio: 'inherit' });
      console.log('✅ PostgreSQL dependencies installed');
    } catch (error) {
      console.log('⚠️  Dependencies might already be installed');
    }
    
    console.log('\n📋 Step 2: Testing PostgreSQL connection...');
    
    // Test PostgreSQL connection
    const prisma = new PrismaClient({
      datasources: {
        db: {
          url: POSTGRES_URL,
        },
      },
    });
    
    try {
      await prisma.$connect();
      console.log('✅ PostgreSQL connection successful');
    } catch (error) {
      console.error('❌ PostgreSQL connection failed:', error.message);
      console.log('\n🔧 Please ensure PostgreSQL is running and accessible with:');
      console.log('   - Host: localhost');
      console.log('   - Port: 5432');
      console.log('   - Database: SERV');
      console.log('   - Username: postgres');
      console.log('   - Password: Nishali');
      process.exit(1);
    }
    
    console.log('\n📋 Step 3: Generating Prisma client...');
    
    // Generate Prisma client
    try {
      execSync('npx prisma generate', { stdio: 'inherit' });
      console.log('✅ Prisma client generated');
    } catch (error) {
      console.error('❌ Failed to generate Prisma client:', error.message);
      process.exit(1);
    }
    
    console.log('\n📋 Step 4: Running database migrations...');
    
    // Run migrations
    try {
      execSync('npx prisma migrate dev --name init-postgresql', { stdio: 'inherit' });
      console.log('✅ Database migrations completed');
    } catch (error) {
      console.error('❌ Failed to run migrations:', error.message);
      process.exit(1);
    }
    
    console.log('\n📋 Step 5: Seeding database...');
    
    // Seed database
    try {
      execSync('npm run db:seed', { stdio: 'inherit' });
      console.log('✅ Database seeded successfully');
    } catch (error) {
      console.log('⚠️  Seeding failed or already completed:', error.message);
    }
    
    console.log('\n🎉 PostgreSQL setup completed successfully!');
    console.log('\n📊 Database Information:');
    console.log(`   - URL: ${POSTGRES_URL}`);
    console.log('   - Provider: PostgreSQL');
    console.log('   - Status: Ready');
    
    console.log('\n🚀 Next steps:');
    console.log('   1. Run data migration: npm run migrate:data');
    console.log('   2. Start the server: npm run dev');
    console.log('   3. Open Prisma Studio: npm run db:studio');
    
    await prisma.$disconnect();
    
  } catch (error) {
    console.error('❌ Setup failed:', error);
    process.exit(1);
  }
}

setupPostgreSQL(); 