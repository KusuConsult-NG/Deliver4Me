import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { hashPassword, verifyPassword } from '@/lib/auth';

/**
 * Change Password
 * PUT /api/v1/users/password
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
        const { currentPassword, newPassword } = body;

        if (!currentPassword || !newPassword) {
            return NextResponse.json(
                errorResponse('Current password and new password are required', 400),
                { status: 400 }
            );
        }

        if (newPassword.length < 6) {
            return NextResponse.json(
                errorResponse('New password must be at least 6 characters', 400),
                { status: 400 }
            );
        }

        // Get user with password
        const user = await prisma.user.findUnique({
            where: { id: authResult.userId },
            select: { id: true, password: true }
        });

        if (!user) {
            return NextResponse.json(
                errorResponse('User not found', 404),
                { status: 404 }
            );
        }

        // Verify current password
        const isValid = await verifyPassword(currentPassword, user.password);
        if (!isValid) {
            return NextResponse.json(
                errorResponse('Current password is incorrect', 401),
                { status: 401 }
            );
        }

        // Hash new password
        const hashedPassword = await hashPassword(newPassword);

        // Update password
        await prisma.user.update({
            where: { id: authResult.userId },
            data: { password: hashedPassword }
        });

        return NextResponse.json(
            successResponse(
                { message: 'Password changed successfully' },
                'Password changed successfully'
            )
        );

    } catch (error: any) {
        console.error('Change password error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
