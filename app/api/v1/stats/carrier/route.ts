import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Get Carrier Statistics
 * GET /api/v1/stats/carrier
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

        // Get carrier stats
        const [
            totalBidsPlaced,
            bidsAccepted,
            bidsPending,
            totalJobs,
            activeJobs,
            completedJobs,
            totalEarnings,
            pendingPayouts
        ] = await Promise.all([
            // Total bids placed
            prisma.bid.count({
                where: { carrierId: userId }
            }),

            // Accepted bids
            prisma.bid.count({
                where: {
                    carrierId: userId,
                    status: 'ACCEPTED'
                }
            }),

            // Pending bids
            prisma.bid.count({
                where: {
                    carrierId: userId,
                    status: 'PENDING'
                }
            }),

            // Total jobs (carrier assigned)
            prisma.job.count({
                where: { carrierId: userId }
            }),

            // Active jobs
            prisma.job.count({
                where: {
                    carrierId: userId,
                    status: { in: ['MATCHED', 'IN_TRANSIT'] }
                }
            }),

            // Completed jobs
            prisma.job.count({
                where: {
                    carrierId: userId,
                    status: 'DELIVERED'
                }
            }),

            // Total earnings (completed payments)
            prisma.payment.aggregate({
                where: {
                    job: { carrierId: userId },
                    status: 'COMPLETED'
                },
                _sum: { carrierAmount: true }
            }),

            // Pending payouts (processing payments)
            prisma.payment.aggregate({
                where: {
                    job: { carrierId: userId },
                    status: 'PROCESSING'
                },
                _sum: { carrierAmount: true }
            })
        ]);

        // Calculate success rate
        const successRate = totalBidsPlaced > 0
            ? Math.round((bidsAccepted / totalBidsPlaced) * 100)
            : 0;

        // Get recent bids
        const recentBids = await prisma.bid.findMany({
            where: { carrierId: userId },
            orderBy: { createdAt: 'desc' },
            take: 5,
            include: {
                job: {
                    select: {
                        id: true,
                        cargoType: true,
                        status: true,
                        pickupAddress: true,
                        dropoffAddress: true
                    }
                }
            }
        });

        return NextResponse.json(
            successResponse({
                summary: {
                    totalBidsPlaced,
                    bidsAccepted,
                    bidsPending,
                    successRate,
                    totalJobs,
                    activeJobs,
                    completedJobs,
                    totalEarnings: totalEarnings._sum.carrierAmount || 0,
                    pendingPayouts: pendingPayouts._sum.carrierAmount || 0,
                    averageEarningsPerJob: completedJobs > 0
                        ? Math.round((totalEarnings._sum.carrierAmount || 0) / completedJobs)
                        : 0
                },
                recentActivity: recentBids
            }, 'Statistics retrieved successfully')
        );

    } catch (error: any) {
        console.error('Carrier stats error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
