import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Cancel Job
 * POST /api/v1/jobs/[id]/cancel
 * 
 * Allows shippers to cancel jobs before they're matched,
 * and drivers to cancel jobs after accepting (with penalty tracking)
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
        const body = await request.json();
        const { reason } = body;

        // Get the job
        const job = await prisma.job.findUnique({
            where: { id: jobId },
            include: {
                shipper: { select: { id: true } },
                carrier: { select: { id: true } },
            },
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Determine who is cancelling and validate permissions
        const isShipper = job.shipperId === authResult.userId;
        const isCarrier = job.carrierId === authResult.userId;

        if (!isShipper && !isCarrier) {
            return NextResponse.json(
                errorResponse('You do not have permission to cancel this job', 403),
                { status: 403 }
            );
        }

        // Validate cancellation based on job status
        if (isShipper) {
            // Shipper can cancel if job is POSTED or MATCHED (before pickup)
            if (job.status !== 'POSTED' && job.status !== 'MATCHED') {
                return NextResponse.json(
                    errorResponse('Job cannot be cancelled at this stage', 400),
                    { status: 400 }
                );
            }
        }

        if (isCarrier) {
            // Driver can cancel if job is MATCHED (before starting delivery)
            if (job.status !== 'MATCHED') {
                return NextResponse.json(
                    errorResponse('You can only cancel before starting delivery', 400),
                    { status: 400 }
                );
            }
        }

        // Cancel the job
        const cancelledJob = await prisma.job.update({
            where: { id: jobId },
            data: {
                status: 'CANCELLED',
                cancelledAt: new Date(),
                cancellationReason: reason || (isShipper ? 'Cancelled by shipper' : 'Cancelled by driver'),
            },
            include: {
                shipper: {
                    select: { id: true, name: true, phone: true },
                },
                carrier: {
                    select: { id: true, name: true, phone: true },
                },
            },
        });

        // Update payment status to REFUNDED if payment exists
        await prisma.payment.updateMany({
            where: { jobId: jobId },
            data: { status: 'REFUNDED' },
        });

        return NextResponse.json(
            successResponse(
                cancelledJob,
                `Job cancelled successfully by ${isShipper ? 'shipper' : 'driver'}`
            )
        );

    } catch (error: any) {
        console.error('Cancel job error:', error);
        return NextResponse.json(
            errorResponse('Failed to cancel job', 500),
            { status: 500 }
        );
    }
}
