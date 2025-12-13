import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Add Tracking Point
 * POST /api/v1/tracking
 */
export async function POST(request: NextRequest) {
    try {
        const authResult = await requireAuth(request);
        if (!authResult.valid || !authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized', 401),
                { status: 401 }
            );
        }

        const body = await request.json();
        const { jobId, latitude, longitude, notes } = body;

        if (!jobId || latitude === undefined || longitude === undefined) {
            return NextResponse.json(
                errorResponse('jobId, latitude, and longitude are required', 400),
                { status: 400 }
            );
        }

        // Verify job exists and user is the carrier
        const job = await prisma.job.findUnique({
            where: { id: jobId }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        if (job.carrierId !== authResult.userId && job.driverId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('Only assigned carrier/driver can add tracking', 403),
                { status: 403 }
            );
        }

        // Create tracking point (use current user as driver)
        const driverId = job.driverId || authResult.userId;

        const trackingPoint = await prisma.trackingPoint.create({
            data: {
                jobId,
                driverId,
                lat: latitude,
                lng: longitude,
            }
        });

        return NextResponse.json(
            successResponse(trackingPoint, 'Tracking point added')
        );

    } catch (error: any) {
        console.error('Add tracking error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
