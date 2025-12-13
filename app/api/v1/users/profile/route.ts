import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { hashPassword } from '@/lib/auth';

/**
 * Get User Profile
 * GET /api/v1/users/profile
 */
export async function GET(request: NextRequest) {
    try {
        const authResult = await requireAuth(request);
        if (!authResult.valid || !authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized', 401),
                { status: 401 }
            );
        }

        const user = await prisma.user.findUnique({
            where: { id: authResult.userId },
            select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                role: true,
                kycStatus: true,
                rating: true,
                totalJobs: true,
                isActive: true,
                createdAt: true,
            }
        });

        if (!user) {
            return NextResponse.json(
                errorResponse('User not found', 404),
                { status: 404 }
            );
        }

        return NextResponse.json(
            successResponse(user, 'Profile retrieved successfully')
        );

    } catch (error: any) {
        console.error('Get profile error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

/**
 * Update User Profile
 * PUT /api/v1/users/profile
 */
export async function PUT(request: NextRequest) {
    try {
        const authResult = await requireAuth(request);
        if (!authResult.valid || !authResult.userId) {
            return NextResponse.json(
                errorResponse('Unauthorized', 401),
                { status: 401 }
            );
        }

        const body = await request.json();

        // Allowed fields to update
        const allowedUpdates: any = {};
        if (body.name) allowedUpdates.name = body.name;
        if (body.email) allowedUpdates.email = body.email;

        if (Object.keys(allowedUpdates).length === 0) {
            return NextResponse.json(
                errorResponse('No valid fields to update', 400),
                { status: 400 }
            );
        }

        const updatedUser = await prisma.user.update({
            where: { id: authResult.userId },
            data: allowedUpdates,
            select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                role: true,
                kycStatus: true,
                rating: true,
                totalJobs: true,
            }
        });

        return NextResponse.json(
            successResponse(updatedUser, 'Profile updated successfully')
        );

    } catch (error: any) {
        console.error('Update profile error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
