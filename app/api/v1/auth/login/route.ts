import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import {
    verifyPassword,
    generateAccessToken,
    generateRefreshToken,
    normalizePhone,
} from '@/lib/auth';
import { successResponse, errorResponse } from '@/lib/response';
import { z } from 'zod';

const loginSchema = z.object({
    phone: z.string().min(10, 'Invalid phone number'),
    password: z.string().min(1, 'Password is required'),
});

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();

        // Validate input
        const validation = loginSchema.safeParse(body);
        if (!validation.success) {
            return NextResponse.json(
                errorResponse(validation.error.issues[0].message, 400),
                { status: 400 }
            );
        }

        const { phone, password } = validation.data;

        // Normalize phone number
        const normalizedPhone = normalizePhone(phone);

        // Find user
        const user = await prisma.user.findUnique({
            where: { phone: normalizedPhone },
            select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                role: true,
                kycStatus: true,
                password: true,
                isActive: true,
            },
        });

        if (!user) {
            return NextResponse.json(
                errorResponse('Invalid phone number or password', 401),
                { status: 401 }
            );
        }

        // Verify password
        const isPasswordValid = await verifyPassword(password, user.password);
        if (!isPasswordValid) {
            return NextResponse.json(
                errorResponse('Invalid phone number or password', 401),
                { status: 401 }
            );
        }

        // Check if user is active
        if (!user.isActive) {
            return NextResponse.json(
                errorResponse('Your account has been deactivated. Please contact support.', 403),
                { status: 403 }
            );
        }

        // Generate tokens
        const accessToken = generateAccessToken({
            userId: user.id,
            phone: user.phone,
            role: user.role,
        });

        const refreshToken = generateRefreshToken({
            userId: user.id,
            phone: user.phone,
            role: user.role,
        });

        // Remove password from response
        const { password: _, ...userWithoutPassword } = user;

        return NextResponse.json(
            successResponse(
                {
                    user: userWithoutPassword,
                    accessToken,
                    refreshToken,
                },
                'Login successful'
            )
        );
    } catch (error: any) {
        console.error('Login error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
