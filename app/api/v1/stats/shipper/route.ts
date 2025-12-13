import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Get Shipper Statistics
 * GET /api/v1/stats/shipper
 */
export async function GET(request: NextRequest) {
    try {
        // Verify authentication
        const authResult = await requireAuth(request);
        if (!authResult.valid || !authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized', 401),
                { status: 401 }
            );
        }

        const userId = authResult.userId;

        // Get shipper stats
        const [
            totalJobs,
            activeJobs,
            completedJobs,
            totalSpent,
            pendingPayments,
            totalBidsReceived
        ] = await Promise.all([
            // Total jobs created
            prisma.job.count({
                where: { shipperId: userId }
            }),

            // Active jobs (POSTED, MATCHED, IN_TRANSIT)
            prisma.job.count({
                where: {
                    shipperId: userId,
                    status: { in: ['POSTED', 'MATCHED', 'IN_TRANSIT'] }
                }
            }),

            // Completed jobs
            prisma.job.count({
                where: {
                    shipperId: userId,
                    status: 'DELIVERED'
                }
            }),

            // Total amount spent (completed payments)
            prisma.payment.aggregate({
                where: {
                    job: { shipperId: userId },
                    status: 'COMPLETED'
                },
                _sum: { amount: true }
            }),

            // Pending payments
            prisma.payment.aggregate({
                where: {
                    job: { shipperId: userId },
                    status: { in: ['PENDING', 'PROCESSING'] }
                },
                _sum: { amount: true }
            }),

            // Total bids received across all jobs
            prisma.bid.count({
                where: {
                    job: { shipperId: userId }
                }
            })
        ]);

        // Get recent activity
        const recentJobs = await prisma.job.findMany({
            where: { shipperId: userId },
            orderBy: { createdAt: 'desc' },
            take: 5,
            select: {
                id: true,
                status: true,
                cargoType: true,
                computedPrice: true,
                createdAt: true,
                _count: {
                    select: { bids: true }
                }
            }
        });

        return NextResponse.json(
            successResponse({
                summary: {
                    totalJobs,
                    activeJobs,
                    completedJobs,
                    totalSpent: totalSpent._sum.amount || 0,
                    pendingPayments: pendingPayments._sum.amount || 0,
                    totalBidsReceived,
                    averageBidsPerJob: totalJobs > 0
                        ? Math.round(totalBidsReceived / totalJobs)
                        : 0
                },
                recentActivity: recentJobs
            }, 'Statistics retrieved successfully')
        );

    } catch (error: any) {
        console.error('Shipper stats error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
