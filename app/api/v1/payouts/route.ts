import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * GET /api/v1/payouts
 * Get payout history for the authenticated carrier
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

        // Only carriers/drivers can request payouts
        if (role !== 'CARRIER' && role !== 'DRIVER') {
            return NextResponse.json(
                errorResponse('Only carriers/drivers can access payouts', 403),
                { status: 403 }
            );
        }

        const { searchParams } = new URL(request.url);
        const status = searchParams.get('status');
        const limit = parseInt(searchParams.get('limit') || '50');

        const where: any = { carrierId: userId };

        if (status) {
            where.status = status;
        }

        const payouts = await prisma.payout.findMany({
            where,
            orderBy: { initiatedAt: 'desc' },
            take: limit,
        });

        return NextResponse.json(
            successResponse({ payouts }),
            { status: 200 }
        );
    } catch (error: any) {
        console.error('Error fetching payouts:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to fetch payouts', 500),
            { status: 500 }
        );
    }
}

/**
 * POST /api/v1/payouts
 * Request a new payout
 */
export async function POST(request: NextRequest) {
    try {
        const auth = await requireAuth(request);
        if (!auth.valid) {
            return NextResponse.json(
                errorResponse(auth.error || 'Unauthorized', 401),
                { status: 401 }
            );
        }
        const { userId, role } = auth;

        // Only carriers/drivers can request payouts
        if (role !== 'CARRIER' && role !== 'DRIVER') {
            return NextResponse.json(
                errorResponse('Only carriers/drivers can request payouts', 403),
                { status: 403 }
            );
        }

        const body = await request.json();
        const { amount, bankName, accountNumber, accountName, notes } = body;

        // Validate required fields
        if (!amount || !bankName || !accountNumber || !accountName) {
            return NextResponse.json(
                errorResponse('Missing required fields: amount, bankName, accountNumber, accountName'),
                { status: 400 }
            );
        }

        // Validate minimum payout amount (e.g., ₦1000)
        const MIN_PAYOUT = 1000;
        if (amount < MIN_PAYOUT) {
            return NextResponse.json(
                errorResponse(`Minimum payout amount is ₦${MIN_PAYOUT.toLocaleString()}`, 400),
                { status: 400 }
            );
        }

        // Calculate available balance
        // Sum of all completed job payments where this user is the carrier
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

        // Sum of all completed payouts
        const completedPayouts = await prisma.payout.findMany({
            where: {
                carrierId: userId,
                status: 'COMPLETED',
            },
            select: {
                amount: true,
            },
        });

        const totalPayouts = completedPayouts.reduce(
            (sum: number, payout: any) => sum + payout.amount,
            0
        );

        // Sum of pending/processing payouts
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

        const availableBalance = totalEarnings - totalPayouts - totalPending;

        // Check if user has sufficient balance
        if (amount > availableBalance) {
            return NextResponse.json(
                errorResponse(
                    `Insufficient balance. Available: ₦${availableBalance.toLocaleString()}, Requested: ₦${amount.toLocaleString()}`,
                    400
                ),
                { status: 400 }
            );
        }

        // Calculate platform fee (e.g., 2% of payout)
        const PLATFORM_FEE_PERCENTAGE = 0.02;
        const platformFee = amount * PLATFORM_FEE_PERCENTAGE;
        const netAmount = amount - platformFee;

        // Generate unique reference
        const reference = `PAYOUT-${Date.now()}-${userId.substring(0, 8)}`;

        // Create payout request
        const payout = await prisma.payout.create({
            data: {
                carrierId: userId,
                amount,
                platformFee,
                netAmount,
                bankName,
                accountNumber,
                accountName,
                reference,
                notes: notes || null,
                status: 'PENDING',
            },
        });

        // TODO: In production, integrate with a payment provider to process the payout
        // For now, we just create the payout record

        // Create notification
        await prisma.notification.create({
            data: {
                userId,
                type: 'PAYOUT_PROCESSED',
                title: 'Payout Request Submitted',
                message: `Your payout request for ₦${amount.toLocaleString()} has been submitted and is being processed.`,
                data: { payoutId: payout.id, amount, reference },
            },
        });

        return NextResponse.json(
            successResponse(payout, 'Payout request created successfully'),
            { status: 201 }
        );
    } catch (error: any) {
        console.error('Error creating payout:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to create payout', 500),
            { status: 500 }
        );
    }
}
