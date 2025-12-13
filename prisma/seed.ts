import { PrismaClient } from '@prisma/client';
import { hashPassword } from '../lib/auth';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding database...');

    // Create test shipper
    const shipper = await prisma.user.upsert({
        where: { phone: '08012345678' },
        update: {},
        create: {
            name: 'Test Shipper',
            phone: '08012345678',
            email: 'shipper@test.com',
            password: await hashPassword('password123'),
            role: 'SHIPPER',
            kycStatus: 'VERIFIED',
            rating: 4.5,
            totalJobs: 0,
        },
    });
    console.log('✅ Created shipper:', shipper.phone);

    // Create test carrier
    const carrier = await prisma.user.upsert({
        where: { phone: '08098765432' },
        update: {},
        create: {
            name: 'Test Carrier',
            phone: '08098765432',
            email: 'carrier@test.com',
            password: await hashPassword('password123'),
            role: 'CARRIER',
            kycStatus: 'VERIFIED',
            rating: 4.8,
            totalJobs: 0,
        },
    });
    console.log('✅ Created carrier:', carrier.phone);

    // Create test driver
    const driver = await prisma.user.upsert({
        where: { phone: '08055555555' },
        update: {},
        create: {
            name: 'Test Driver',
            phone: '08055555555',
            email: 'driver@test.com',
            password: await hashPassword('password123'),
            role: 'DRIVER',
            kycStatus: 'VERIFIED',
            rating: 4.7,
            totalJobs: 0,
            isOnline: false,
        },
    });
    console.log('✅ Created driver:', driver.phone);

    console.log('🎉 Seeding completed successfully!');
    console.log('\nTest Credentials:');
    console.log('Shipper: 08012345678 / password123');
    console.log('Carrier: 08098765432 / password123');
    console.log('Driver:  08055555555 / password123');
}

main()
    .catch((e) => {
        console.error('❌ Error seeding database:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
