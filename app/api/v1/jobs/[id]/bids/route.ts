import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { authenticate } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { z } from 'zod';

const createBidSchema = z.object({
    amount: z.number().min(100, 'Bid amount must be at least ₦100'),
    etaMinutes: z.number().optional(),
    message: z.string().optional(),
});

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

        // Only carriers and drivers can bid
        if (auth.user!.role !== 'CARRIER' && auth.user!.role !== 'DRIVER') {
            return NextResponse.json(
                errorResponse('Only carriers and drivers can place bids', 403),
                { status: 403 }
            );
        }

        const body = await request.json();

        // Validate input
        const validation = createBidSchema.safeParse(body);
        if (!validation.success) {
            return NextResponse.json(
                errorResponse(validation.error.issues[0].message, 400),
                { status: 400 }
            );
        }

        const data = validation.data;

        // Check if job exists and is available
        const job = await prisma.job.findUnique({
            where: { id: params.id },
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        if (job.status !== 'POSTED') {
            return NextResponse.json(
                errorResponse('This job is no longer accepting bids', 400),
                { status: 400 }
            );
        }

        // Check if user already bid on this job
        const existingBid = await prisma.bid.findFirst({
            where: {
                jobId: params.id,
                carrierId: auth.user!.userId,
            },
        });

        if (existingBid) {
            return NextResponse.json(
                errorResponse('You have already placed a bid on this job', 400),
                { status: 400 }
            );
        }

        // Create bid
        const bid = await prisma.bid.create({
            data: {
                jobId: params.id,
                carrierId: auth.user!.userId,
                amount: data.amount,
                etaMinutes: data.etaMinutes,
                message: data.message,
            },
            include: {
                carrier: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        rating: true,
                        totalJobs: true,
                    },
                },
            },
        });

        return NextResponse.json(
            successResponse(bid, 'Bid submitted successfully'),
            { status: 201 }
        );
    } catch (error: any) {
        console.error('Create bid error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

export async function GET(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    try {
        // Authenticate user
        const auth = authenticate(request);
        if (!auth.authenticated) {
            return NextResponse.json(auth.error, { status: 401 });
        }

        const bids = await prisma.bid.findMany({
            where: { jobId: params.id },
            include: {
                carrier: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        rating: true,
                        totalJobs: true,
                    },
                },
            },
            orderBy: { createdAt: 'desc' },
        });

        return NextResponse.json(successResponse(bids));
    } catch (error: any) {
        console.error('Get bids error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
