import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Start Job Delivery
 * POST /api/v1/jobs/[id]/start
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

        const { id } = params;

        // Get job
        const job = await prisma.job.findUnique({
            where: { id },
            include: {
                carrier: true,
                shipper: true,
            }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Verify carrier owns this job
        if (job.carrierId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('Only assigned carrier can start delivery', 403),
                { status: 403 }
            );
        }

        // Check job status
        if (job.status !== 'MATCHED') {
            return NextResponse.json(
                errorResponse(`Cannot start job with status ${job.status}`, 400),
                { status: 400 }
            );
        }

        // Update job status
        const updatedJob = await prisma.job.update({
            where: { id },
            data: {
                status: 'IN_TRANSIT',
                startedAt: new Date(),
            },
            include: {
                shipper: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                    }
                },
                carrier: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                    }
                }
            }
        });

        return NextResponse.json(
            successResponse(updatedJob, 'Delivery started successfully')
        );

    } catch (error: any) {
        console.error('Start delivery error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
