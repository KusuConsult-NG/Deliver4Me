import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { authenticate } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { calculatePlatformFee, calculateCarrierAmount } from '@/lib/pricing';

export async function POST(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    try {
        // Authenticate user
        const auth = authenticate(request);
        if (!auth.authenticated) {
            return NextResponse.json(auth.error, { status: 401 });
        }

        const body = await request.json();
        const { bidId } = body;

        // Get job
        const job = await prisma.job.findUnique({
            where: { id: params.id },
            include: {
                bids: {
                    where: { id: bidId },
                    include: {
                        carrier: true,
                    },
                },
            },
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Check permissions - only shipper can accept bids
        if (job.shipperId !== auth.user!.userId) {
            return NextResponse.json(
                errorResponse('Only the job creator can accept bids', 403),
                { status: 403 }
            );
        }

        if (job.status !== 'POSTED') {
            return NextResponse.json(
                errorResponse('This job is no longer accepting bids', 400),
                { status: 400 }
            );
        }

        const bid = job.bids[0];
        if (!bid) {
            return NextResponse.json(
                errorResponse('Bid not found', 404),
                { status: 404 }
            );
        }

        // Update job and bid in transaction
        const [updatedJob, _, rejectedBids] = await prisma.$transaction([
            // Update job
            prisma.job.update({
                where: { id: params.id },
                data: {
                    status: 'MATCHED',
                    acceptedBidId: bidId,
                    carrierId: bid.carrierId,
                    finalPrice: bid.amount,
                    acceptedAt: new Date(),
                },
                include: {
                    shipper: {
                        select: { id: true, name: true, phone: true },
                    },
                    carrier: {
                        select: { id: true, name: true, phone: true, rating: true },
                    },
                },
            }),
            // Accept the winning bid
            prisma.bid.update({
                where: { id: bidId },
                data: { status: 'ACCEPTED' },
            }),
            // Reject other bids
            prisma.bid.updateMany({
                where: {
                    jobId: params.id,
                    id: { not: bidId },
                },
                data: { status: 'REJECTED' },
            }),
        ]);

        // Create payment record
        const platformFee = calculatePlatformFee(bid.amount);
        const carrierAmount = calculateCarrierAmount(bid.amount);

        await prisma.payment.create({
            data: {
                jobId: updatedJob.id,
                amount: bid.amount,
                platformFee,
                carrierAmount,
                status: 'PENDING',
            },
        });

        return NextResponse.json(
            successResponse(updatedJob, 'Bid accepted successfully')
        );
    } catch (error: any) {
        console.error('Accept bid error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
