import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { calculatePlatformFee, calculateCarrierAmount } from '@/lib/pricing';

/**
 * Instant Accept Job (Uber/Bolt Style)
 * POST /api/v1/jobs/[id]/instant-accept
 * 
 * Allows a driver to instantly accept a delivery job on a first-come, first-served basis.
 * Uses database transactions to prevent race conditions where multiple drivers 
 * attempt to accept the same job simultaneously.
 */
export async function POST(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    try {
        const authResult = await requireAuth(request);
        if (!authResult.valid || !authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized', 401),
                { status: 401 }
            );
        }

        const jobId = params.id;

        // Get driver info and validate
        const driver = await prisma.user.findUnique({
            where: { id: authResult.userId },
            include: {
                vehicles: {
                    where: { isActive: true },
                    take: 1,
                },
            },
        });

        if (!driver) {
            return NextResponse.json(
                errorResponse('Driver not found', 404),
                { status: 404 }
            );
        }

        // Validate driver role
        if (driver.role !== 'CARRIER' && driver.role !== 'DRIVER') {
            return NextResponse.json(
                errorResponse('Only drivers can accept jobs', 403),
                { status: 403 }
            );
        }

        // Check if driver is online
        if (!driver.isOnline) {
            return NextResponse.json(
                errorResponse('You must be online to accept jobs', 400),
                { status: 400 }
            );
        }

        // Check if driver has a vehicle
        if (driver.vehicles.length === 0) {
            return NextResponse.json(
                errorResponse('You must have an active vehicle to accept jobs', 400),
                { status: 400 }
            );
        }

        // Get current location from request body
        const body = await request.json();
        const { latitude, longitude } = body;

        // Update driver location if provided
        if (latitude && longitude) {
            await prisma.user.update({
                where: { id: authResult.userId },
                data: {
                    currentLat: latitude,
                    currentLng: longitude,
                    lastLocationUpdate: new Date(),
                },
            });
        }

        // Attempt to accept the job atomically
        // This prevents race conditions by using Prisma's updateMany with conditions
        const result = await prisma.$transaction(async (tx) => {
            // First, check if job is still available
            const job = await tx.job.findUnique({
                where: { id: jobId },
                include: {
                    shipper: {
                        select: {
                            id: true,
                            name: true,
                            phone: true,
                            rating: true,
                        },
                    },
                },
            });

            if (!job) {
                throw new Error('JOB_NOT_FOUND');
            }

            // Validate job is available for instant accept
            if (job.bookingMode !== 'AUTO_ACCEPT') {
                throw new Error('JOB_NOT_AUTO_ACCEPT');
            }

            if (job.status !== 'POSTED') {
                throw new Error('JOB_ALREADY_TAKEN');
            }

            // Check if job has expired
            if (job.expiresAt && job.expiresAt < new Date()) {
                throw new Error('JOB_EXPIRED');
            }

            // Atomic update - only updates if status is still POSTED
            const updateResult = await tx.job.updateMany({
                where: {
                    id: jobId,
                    status: 'POSTED', // Critical: only update if still posted
                },
                data: {
                    status: 'MATCHED',
                    carrierId: authResult.userId,
                    finalPrice: job.computedPrice || 0,
                    acceptedAt: new Date(),
                },
            });

            // If count is 0, job was already accepted by another driver
            if (updateResult.count === 0) {
                throw new Error('JOB_ALREADY_TAKEN');
            }

            // Get the updated job
            const updatedJob = await tx.job.findUnique({
                where: { id: jobId },
                include: {
                    shipper: {
                        select: {
                            id: true,
                            name: true,
                            phone: true,
                            rating: true,
                        },
                    },
                },
            });

            // Create payment record
            const platformFee = calculatePlatformFee(job.computedPrice || 0);
            const carrierAmount = calculateCarrierAmount(job.computedPrice || 0);

            await tx.payment.create({
                data: {
                    jobId: jobId,
                    amount: job.computedPrice || 0,
                    platformFee,
                    carrierAmount,
                    status: 'PENDING',
                },
            });

            return updatedJob;
        });

        return NextResponse.json(
            successResponse(
                {
                    job: result,
                    message: 'Job accepted successfully! Navigate to pickup location.',
                },
                'Job accepted successfully'
            ),
            { status: 200 }
        );

    } catch (error: any) {
        console.error('Instant accept error:', error);

        // Handle specific error cases
        if (error.message === 'JOB_NOT_FOUND') {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        if (error.message === 'JOB_NOT_AUTO_ACCEPT') {
            return NextResponse.json(
                errorResponse('This job requires bidding, not instant accept', 400),
                { status: 400 }
            );
        }

        if (error.message === 'JOB_ALREADY_TAKEN') {
            return NextResponse.json(
                errorResponse('This job was just accepted by another driver', 409),
                { status: 409 }
            );
        }

        if (error.message === 'JOB_EXPIRED') {
            return NextResponse.json(
                errorResponse('This job has expired', 410),
                { status: 410 }
            );
        }

        return NextResponse.json(
            errorResponse('Failed to accept job', 500),
            { status: 500 }
        );
    }
}
