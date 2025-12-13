import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Get User Ratings
 * GET /api/v1/users/[id]/ratings
 */
export async function GET(
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

        // Get user ratings
        const ratings = await prisma.rating.findMany({
            where: { ratedUserId: id },
            include: {
                ratedBy: {
                    select: {
                        id: true,
                        name: true,
                        role: true,
                    }
                },
                job: {
                    select: {
                        id: true,
                        cargoType: true,
                        createdAt: true,
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        // Get user info
        const user = await prisma.user.findUnique({
            where: { id },
            select: {
                id: true,
                name: true,
                role: true,
                rating: true,
                totalJobs: true,
            }
        });

        if (!user) {
            return NextResponse.json(
                errorResponse('User not found', 404),
                { status: 404 }
            );
        }

        // Calculate rating distribution
        const distribution = {
            5: ratings.filter(r => r.score === 5).length,
            4: ratings.filter(r => r.score === 4).length,
            3: ratings.filter(r => r.score === 3).length,
            2: ratings.filter(r => r.score === 2).length,
            1: ratings.filter(r => r.score === 1).length,
        };

        return NextResponse.json(
            successResponse({
                user,
                ratings,
                summary: {
                    totalRatings: ratings.length,
                    averageRating: user.rating,
                    distribution
                }
            }, 'Ratings retrieved successfully')
        );

    } catch (error: any) {
        console.error('Get ratings error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
