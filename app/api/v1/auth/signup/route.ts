import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import {
    hashPassword,
    generateAccessToken,
    generateRefreshToken,
    validatePhone,
    normalizePhone,
} from '@/lib/auth';
import { successResponse, errorResponse } from '@/lib/response';
import { z } from 'zod';

const signupSchema = z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    phone: z.string().refine(validatePhone, 'Invalid phone number format'),
    email: z.string().email().optional().or(z.literal('')),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    role: z.enum(['SHIPPER', 'CARRIER', 'DRIVER']),
});

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();

        // Validate input
        const validation = signupSchema.safeParse(body);
        if (!validation.success) {
            return NextResponse.json(
                errorResponse(validation.error.issues[0].message, 400),
                { status: 400 }
            );
        }

        const { name, phone, email, password, role } = validation.data;

        // Normalize phone number
        const normalizedPhone = normalizePhone(phone);

        // Check if user already exists
        const existingUser = await prisma.user.findUnique({
            where: { phone: normalizedPhone },
        });

        if (existingUser) {
            return NextResponse.json(
                errorResponse('User with this phone number already exists', 400),
                { status: 400 }
            );
        }

        // Check email if provided
        if (email) {
            const existingEmail = await prisma.user.findUnique({
                where: { email },
            });

            if (existingEmail) {
                return NextResponse.json(
                    errorResponse('User with this email already exists', 400),
                    { status: 400 }
                );
            }
        }

        // Hash password
        const hashedPassword = await hashPassword(password);

        // Create user
        const user = await prisma.user.create({
            data: {
                name,
                phone: normalizedPhone,
                email: email || undefined,
                password: hashedPassword,
                role,
            },
            select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                role: true,
                kycStatus: true,
                createdAt: true,
            },
        });

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

        return NextResponse.json(
            successResponse(
                {
                    user,
                    accessToken,
                    refreshToken,
                },
                'Account created successfully'
            ),
            { status: 201 }
        );
    } catch (error: any) {
        console.error('Signup error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
