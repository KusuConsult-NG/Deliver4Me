import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Get Job Details
 * GET /api/v1/jobs/[id]
 */
export async function GET(
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

        const { id } = params;

        const job = await prisma.job.findUnique({
            where: { id },
            include: {
                shipper: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        rating: true,
                    }
                },
                carrier: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        rating: true,
                    }
                },
                _count: {
                    select: { bids: true }
                }
            }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        return NextResponse.json(
            successResponse(job, 'Job retrieved successfully')
        );

    } catch (error: any) {
        console.error('Get job error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

/**
 * Cancel Job
 * DELETE /api/v1/jobs/[id]
 */
export async function DELETE(
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

        const { id } = params;
        const body = await request.json();
        const { reason } = body;

        // Get job
        const job = await prisma.job.findUnique({
            where: { id },
            include: { payments: true }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Only shipper can cancel
        if (job.shipperId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('Only job creator can cancel', 403),
                { status: 403 }
            );
        }

        // Cannot cancel if already delivered or in transit with payment
        if (job.status === 'DELIVERED') {
            return NextResponse.json(
                errorResponse('Cannot cancel delivered job', 400),
                { status: 400 }
            );
        }

        if (job.status === 'IN_TRANSIT') {
            const hasCompletedPayment = job.payments?.some((p: any) => p.status === 'COMPLETED');
            if (hasCompletedPayment) {
                return NextResponse.json(
                    errorResponse('Cannot cancel job with completed payment', 400),
                    { status: 400 }
                );
            }
        }

        // Cancel job
        const cancelledJob = await prisma.job.update({
            where: { id },
            data: {
                status: 'CANCELLED',
                cancelledAt: new Date(),
                cancellationReason: reason || 'No reason provided',
            }
        });

        // Reject all pending bids
        await prisma.bid.updateMany({
            where: {
                jobId: id,
                status: 'PENDING'
            },
            data: {
                status: 'REJECTED'
            }
        });

        return NextResponse.json(
            successResponse(cancelledJob, 'Job cancelled successfully')
        );

    } catch (error: any) {
        console.error('Cancel job error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

/**
 * Update Job
 * PUT /api/v1/jobs/[id]
 */
export async function PUT(
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

        const { id } = params;
        const body = await request.json();

        // Get job
        const job = await prisma.job.findUnique({
            where: { id }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Only shipper can update
        if (job.shipperId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('Only job creator can update', 403),
                { status: 403 }
            );
        }

        // Can only update if POSTED
        if (job.status !== 'POSTED') {
            return NextResponse.json(
                errorResponse('Can only update jobs in POSTED status', 400),
                { status: 400 }
            );
        }

        // Update allowed fields
        const allowedUpdates = {
            pickupAddress: body.pickupAddress,
            dropoffAddress: body.dropoffAddress,
            cargoType: body.cargoType,
            cargoWeight: body.cargoWeight,
            cargoDescription: body.cargoDescription,
        };

        // Remove undefined fields
        Object.keys(allowedUpdates).forEach(key =>
            allowedUpdates[key as keyof typeof allowedUpdates] === undefined &&
            delete allowedUpdates[key as keyof typeof allowedUpdates]
        );

        const updatedJob = await prisma.job.update({
            where: { id },
            data: allowedUpdates
        });

        return NextResponse.json(
            successResponse(updatedJob, 'Job updated successfully')
        );

    } catch (error: any) {
        console.error('Update job error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
