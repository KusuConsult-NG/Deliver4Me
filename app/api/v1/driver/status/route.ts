import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Toggle Driver Online/Offline Status
 * POST /api/v1/driver/status
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

        // Check if user is a carrier/driver
        const user = await prisma.user.findUnique({
            where: { id: authResult.userId },
            select: { role: true }
        });

        if (!user || (user.role !== 'CARRIER' && user.role !== 'DRIVER')) {
            return NextResponse.json(
                errorResponse('Only drivers can change online status', 403),
                { status: 403 }
            );
        }

        const body = await request.json();
        const { isOnline, latitude, longitude } = body;

        // Update driver status
        const updatedUser = await prisma.user.update({
            where: { id: authResult.userId },
            data: {
                isOnline: isOnline,
                ...(latitude && longitude ? {
                    currentLat: latitude,
                    currentLng: longitude,
                    lastLocationUpdate: new Date(),
                } : {}),
            },
            select: {
                id: true,
                name: true,
                isOnline: true,
                currentLat: true,
                currentLng: true,
                todayEarnings: true,
                todayDeliveries: true,
            }
        });

        return NextResponse.json(
            successResponse(updatedUser, `Status changed to ${isOnline ? 'online' : 'offline'}`)
        );

    } catch (error: any) {
        console.error('Toggle status error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

/**
 * Get Driver Status
 * GET /api/v1/driver/status
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
                isOnline: true,
                currentLat: true,
                currentLng: true,
                todayEarnings: true,
                todayDeliveries: true,
                rating: true,
            }
        });

        if (!user) {
            return NextResponse.json(
                errorResponse('User not found', 404),
                { status: 404 }
            );
        }

        return NextResponse.json(
            successResponse(user, 'Driver status retrieved')
        );

    } catch (error: any) {
        console.error('Get status error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
