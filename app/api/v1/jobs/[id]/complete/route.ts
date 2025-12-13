import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Complete Job Delivery
 * POST /api/v1/jobs/[id]/complete
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
                payment: true,
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
                errorResponse('Only assigned carrier can complete delivery', 403),
                { status: 403 }
            );
        }

        // Check job status
        if (job.status !== 'IN_TRANSIT') {
            return NextResponse.json(
                errorResponse(`Cannot complete job with status ${job.status}`, 400),
                { status: 400 }
            );
        }

        // Check if payment is completed
        const hasCompletedPayment = job.payment?.some(p => p.status === 'COMPLETED');
        if (!hasCompletedPayment) {
            return NextResponse.json(
                errorResponse('Payment must be completed before delivery', 400),
                { status: 400 }
            );
        }

        // Update job status
        const updatedJob = await prisma.job.update({
            where: { id },
            data: {
                status: 'DELIVERED',
                completedAt: new Date(),
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
                        rating: true,
                        totalJobs: true,
                    }
                }
            }
        });

        // Update carrier's total jobs count
        await prisma.user.update({
            where: { id: authResult.userId },
            data: {
                totalJobs: { increment: 1 }
            }
        });

        return NextResponse.json(
            successResponse(updatedJob, 'Delivery completed successfully')
        );

    } catch (error: any) {
        console.error('Complete delivery error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
