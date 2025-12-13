import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { z } from 'zod';

const ratingSchema = z.object({
    jobId: z.string().uuid(),
    ratedUserId: z.string().uuid(),
    score: z.number().min(1).max(5),
    comment: z.string().optional(),
});

/**
 * Submit Rating
 * POST /api/v1/ratings
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
        const validation = ratingSchema.safeParse(body);

        if (!validation.success) {
            return NextResponse.json(
                errorResponse(validation.error.issues[0].message, 400),
                { status: 400 }
            );
        }

        const { jobId, ratedUserId, score, comment } = validation.data;

        // Verify job exists and is completed
        const job = await prisma.job.findUnique({
            where: { id: jobId }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        if (job.status !== 'DELIVERED') {
            return NextResponse.json(
                errorResponse('Can only rate completed jobs', 400),
                { status: 400 }
            );
        }

        // Verify user is part of the job
        if (job.shipperId !== authResult.userId &&
            job.carrierId !== authResult.userId &&
            job.driverId !== authResult.userId) {
            return NextResponse.json(
                errorResponse('You are not authorized to rate this job', 403),
                { status: 403 }
            );
        }

        // Prevent rating yourself
        if (ratedUserId === authResult.userId) {
            return NextResponse.json(
                errorResponse('Cannot rate yourself', 400),
                { status: 400 }
            );
        }

        // Check if already rated
        const existingRating = await prisma.rating.findFirst({
            where: {
                jobId,
                ratedById: authResult.userId,
                ratedUserId
            }
        });

        if (existingRating) {
            return NextResponse.json(
                errorResponse('You have already rated this user for this job', 400),
                { status: 400 }
            );
        }

        // Create rating
        const rating = await prisma.rating.create({
            data: {
                jobId,
                ratedById: authResult.userId,
                ratedUserId,
                score,
                comment: comment || null,
            },
            include: {
                ratedBy: {
                    select: { id: true, name: true, role: true }
                },
                ratedUser: {
                    select: { id: true, name: true, role: true }
                }
            }
        });

        // Update user's average rating
        const userRatings = await prisma.rating.findMany({
            where: { ratedUserId },
            select: { score: true }
        });

        const avgRating = userRatings.reduce((sum, r) => sum + r.score, 0) / userRatings.length;

        await prisma.user.update({
            where: { id: ratedUserId },
            data: { rating: Math.round(avgRating * 10) / 10 }
        });

        return NextResponse.json(
            successResponse(rating, 'Rating submitted successfully')
        );

    } catch (error: any) {
        console.error('Submit rating error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
