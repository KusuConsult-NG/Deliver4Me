import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * POST /api/v1/notifications/{id}/read
 * Mark a notification as read
 */
export async function POST(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    try {
        const auth = await requireAuth(request);
        if (!auth.valid) {
            return NextResponse.json(
                errorResponse(auth.error || 'Unauthorized', 401),
                { status: 401 }
            );
        }
        const { userId } = auth;
        const { id } = params;

        // Find the notification and verify ownership
        const notification = await prisma.notification.findUnique({
            where: { id },
        });

        if (!notification) {
            return NextResponse.json(
                errorResponse('Notification not found', 404),
                { status: 404 }
            );
        }

        if (notification.userId !== userId) {
            return NextResponse.json(
                errorResponse('Not authorized to modify this notification', 403),
                { status: 403 }
            );
        }

        // Mark as read
        const updatedNotification = await prisma.notification.update({
            where: { id },
            data: { read: true },
        });

        return NextResponse.json(
            successResponse(updatedNotification, 'Notification marked as read'),
            { status: 200 }
        );
    } catch (error: any) {
        console.error('Error marking notification as read:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to update notification', 500),
            { status: 500 }
        );
    }
}

/**
 * DELETE /api/v1/notifications/{id}/read
 * Mark a notification as unread
 */
export async function DELETE(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    try {
        const auth = await requireAuth(request);
        if (!auth.valid) {
            return NextResponse.json(
                errorResponse(auth.error || 'Unauthorized', 401),
                { status: 401 }
            );
        }
        const { userId } = auth;
        const { id } = params;

        // Find the notification and verify ownership
        const notification = await prisma.notification.findUnique({
            where: { id },
        });

        if (!notification) {
            return NextResponse.json(
                errorResponse('Notification not found', 404),
                { status: 404 }
            );
        }

        if (notification.userId !== userId) {
            return NextResponse.json(
                errorResponse('Not authorized to modify this notification', 403),
                { status: 403 }
            );
        }

        // Mark as unread
        const updatedNotification = await prisma.notification.update({
            where: { id },
            data: { read: false },
        });

        return NextResponse.json(
            successResponse(updatedNotification, 'Notification marked as unread'),
            { status: 200 }
        );
    } catch (error: any) {
        console.error('Error marking notification as unread:', error);
        return NextResponse.json(
            errorResponse(error.message || 'Failed to update notification', 500),
            { status: 500 }
        );
    }
}
