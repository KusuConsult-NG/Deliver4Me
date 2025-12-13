import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Get Job Tracking Points
 * GET /api/v1/jobs/[id]/tracking
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

        // Verify job exists
        const job = await prisma.job.findUnique({
            where: { id }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Only shipper, carrier, or driver can view tracking
        if (job.shipperId !== authResult.userId &&
            job.carrierId !== authResult.userId &&
            job.driverId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized to view tracking', 403),
                { status: 403 }
            );
        }

        // Get tracking points
        const trackingPoints = await prisma.trackingPoint.findMany({
            where: { jobId: id },
            orderBy: { createdAt: 'desc' }
        });

        return NextResponse.json(
            successResponse({
                job: {
                    id: job.id,
                    status: job.status,
                    pickupAddress: job.pickupAddress,
                    dropoffAddress: job.dropoffAddress,
                },
                trackingPoints
            }, 'Tracking retrieved successfully')
        );

    } catch (error: any) {
        console.error('Get tracking error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
