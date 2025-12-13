import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * GET /api/v1/payouts/balance
 * Get current available balance for payout
 */
export async function GET(request: NextRequest) {
    try {
        const auth = await requireAuth(request);
        if (!auth.valid) {
            return NextResponse.json(
                errorResponse(auth.error || 'Unauthorized', 401),
                { status: 401 }
            );
        }
        const { userId, role } = auth;

        // Only carriers/drivers can check balance
        if (role !== 'CARRIER' && role !== 'DRIVER') {
            return NextResponse.json(
                errorResponse('Only carriers/drivers can check balance', 403),
                { status: 403 }
            );
        }

        // Calculate total earnings from completed jobs
        const completedPayments = await prisma.payment.findMany({
            where: {
                status: 'COMPLETED',
                job: {
                    carrierId: userId,
                    status: 'DELIVERED',
                },
            },
            select: {
                carrierAmount: true,
            },
        });

        const totalEarnings = completedPayments.reduce(
            (sum: number, payment: any) => sum + payment.carrierAmount,
            0
        );

        // Calculate total completed payouts
        const completedPayouts = await prisma.payout.findMany({
            where: {
                carrierId: userId,
                status: 'COMPLETED',
            },
            select: {
                amount: true,
            },
        });

        const totalPaidOut = completedPayouts.reduce(
            (sum: number, payout: any) => sum + payout.amount,
            0
        );

        // Calculate pending payouts
        const pendingPayouts = await prisma.payout.findMany({
            where: {
                carrierId: userId,
                status: { in: ['PENDING', 'PROCESSING'] },
            },
            select: {
                amount: true,
            },
        });

        const totalPending = pendingPayouts.reduce(
            (sum: number, payout: any) => sum + payout.amount,
            0
        );

        const availableBalance = totalEarnings - totalPaidOut - totalPending;

        return NextResponse.json(
            successResponse({
                totalEarnings,
                totalPaidOut,
                totalPending,
                availableBalance,
                minPayoutAmount: 1000, // Minimum payout amount in Naira
            }),
            { status: 200 }
        );
    } catch (error: any) {
        console.error('Error fetching balance:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to fetch balance', 500),
            { status: 500 }
        );
    }
}
