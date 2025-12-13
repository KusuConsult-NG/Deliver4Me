import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * GET /api/v1/notifications
 * Get user notifications
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
        const { userId } = auth;

        const { searchParams } = new URL(request.url);
        const unreadOnly = searchParams.get('unread') === 'true';
        const type = searchParams.get('type');
        const limit = parseInt(searchParams.get('limit') || '50');

        const where: any = { userId };

        if (unreadOnly) {
            where.read = false;
        }

        if (type) {
            where.type = type;
        }

        const notifications = await prisma.notification.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            take: limit,
        });

        const unreadCount = await prisma.notification.count({
            where: { userId, read: false },
        });

        return NextResponse.json(
            successResponse({
                notifications,
                unreadCount,
            }),
            { status: 200 }
        );
    } catch (error: any) {
        console.error('Error fetching notifications:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to fetch notifications', 500),
            { status: 500 }
        );
    }
}

/**
 * POST /api/v1/notifications
 * Create a notification (internal use only - typically called by other API routes)
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
        const body = await request.json();

        const { userId, type, title, message, data } = body;

        // Validate required fields
        if (!userId || !type || !title || !message) {
            return NextResponse.json(
                errorResponse('Missing required fields: userId, type, title, message'),
                { status: 400 }
            );
        }

        const notification = await prisma.notification.create({
            data: {
                userId,
                type,
                title,
                message,
                data: data || null,
            },
        });

        return NextResponse.json(
            successResponse(notification, 'Notification created'),
            { status: 201 }
        );
    } catch (error: any) {
        console.error('Error creating notification:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to create notification', 500),
            { status: 500 }
        );
    }
}
