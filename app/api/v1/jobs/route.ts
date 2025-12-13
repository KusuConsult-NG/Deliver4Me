import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { authenticate } from '@/lib/middleware';
import { calculateRoutingDistance } from '@/lib/geo';
import { computePrice } from '@/lib/pricing';
import { successResponse, errorResponse, paginatedResponse } from '@/lib/response';
import { z } from 'zod';

const createJobSchema = z.object({
    pickupAddress: z.string().min(5, 'Pickup address is required'),
    pickupLat: z.number().min(-90).max(90),
    pickupLng: z.number().min(-180).max(180),
    dropoffAddress: z.string().min(5, 'Dropoff address is required'),
    dropoffLat: z.number().min(-90).max(90),
    dropoffLng: z.number().min(-180).max(180),
    cargoType: z.string().min(2, 'Cargo type is required'),
    cargoWeight: z.number().optional(),
    cargoDescription: z.string().optional(),
    bookingMode: z.enum(['AUTO_ACCEPT', 'BIDDING']).default('AUTO_ACCEPT'),
    pricingMode: z.enum(['OPEN_BIDS', 'INSTANT_PRICE', 'NEGOTIABLE']).default('INSTANT_PRICE'),
    maxBudget: z.number().optional(),
});

export async function POST(request: NextRequest) {
    try {
        // Authenticate user
        const auth = authenticate(request);
        if (!auth.authenticated) {
            return NextResponse.json(auth.error, { status: 401 });
        }

        // Only shippers can create jobs
        if (auth.user!.role !== 'SHIPPER') {
            return NextResponse.json(
                errorResponse('Only shippers can create jobs', 403),
                { status: 403 }
            );
        }

        const body = await request.json();

        // Validate input
        const validation = createJobSchema.safeParse(body);
        if (!validation.success) {
            return NextResponse.json(
                errorResponse(validation.error.issues[0].message, 400),
                { status: 400 }
            );
        }

        const data = validation.data;

        // Calculate routing distance
        const distanceKm = await calculateRoutingDistance(
            data.pickupLat,
            data.pickupLng,
            data.dropoffLat,
            data.dropoffLng
        );

        // Compute price based on distance and weight
        const computedPrice = computePrice(distanceKm, data.cargoWeight || 2, true);

        // For 30km+, force pricing mode to NEGOTIABLE
        let pricingMode = data.pricingMode;
        if (distanceKm >= 30) {
            pricingMode = 'NEGOTIABLE';
        }

        // Validate booking mode compatibility
        let bookingMode = data.bookingMode;
        if (bookingMode === 'AUTO_ACCEPT' && pricingMode !== 'INSTANT_PRICE') {
            // Auto-accept requires instant pricing
            pricingMode = 'INSTANT_PRICE';
        }

        // Set expiration time for auto-accept jobs (10 minutes from now)
        const expiresAt = bookingMode === 'AUTO_ACCEPT'
            ? new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
            : null;

        // Create job
        const job = await prisma.job.create({
            data: {
                shipperId: auth.user!.userId,
                pickupAddress: data.pickupAddress,
                pickupLat: data.pickupLat,
                pickupLng: data.pickupLng,
                dropoffAddress: data.dropoffAddress,
                dropoffLat: data.dropoffLat,
                dropoffLng: data.dropoffLng,
                distanceKm,
                computedPrice: computedPrice || 0,
                cargoType: data.cargoType,
                cargoWeight: data.cargoWeight || 2,
                cargoDescription: data.cargoDescription,
                bookingMode,
                pricingMode,
                maxBudget: data.maxBudget,
                expiresAt,
            },
            include: {
                shipper: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                    },
                },
            },
        });

        return NextResponse.json(
            successResponse(job, 'Job created successfully'),
            { status: 201 }
        );
    } catch (error: any) {
        console.error('Create job error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}

export async function GET(request: NextRequest) {
    try {
        // Authenticate user
        const auth = authenticate(request);
        if (!auth.authenticated) {
            return NextResponse.json(auth.error, { status: 401 });
        }

        const { searchParams } = new URL(request.url);
        const page = parseInt(searchParams.get('page') || '1');
        const limit = parseInt(searchParams.get('limit') || '20');
        const status = searchParams.get('status');
        const dateFrom = searchParams.get('dateFrom');
        const dateTo = searchParams.get('dateTo');
        const lat = searchParams.get('lat');
        const lng = searchParams.get('lng');

        const skip = (page - 1) * limit;

        // Build where clause based on role
        let where: any = {};

        if (auth.user!.role === 'SHIPPER') {
            where.shipperId = auth.user!.userId;
        } else if (auth.user!.role === 'CARRIER' || auth.user!.role === 'DRIVER') {
            // Show available jobs or jobs they're assigned to
            where.OR = [
                { status: 'POSTED' },
                { carrierId: auth.user!.userId },
            ];
        }

        if (status) {
            where.status = status;
        }

        // Date range filtering
        if (dateFrom || dateTo) {
            where.createdAt = {};
            if (dateFrom) {
                where.createdAt.gte = new Date(dateFrom);
            }
            if (dateTo) {
                where.createdAt.lte = new Date(dateTo);
            }
        }

        // Get jobs
        const [jobs, total] = await Promise.all([
            prisma.job.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    shipper: {
                        select: {
                            id: true,
                            name: true,
                            phone: true,
                        },
                    },
                    carrier: {
                        select: {
                            id: true,
                            name: true,
                            phone: true,
                            rating: true,
                        },
                    },
                    _count: {
                        select: {
                            bids: true,
                        },
                    },
                },
            }),
            prisma.job.count({ where }),
        ]);

        return NextResponse.json(paginatedResponse(jobs, page, limit, total));
    } catch (error: any) {
        console.error('Get jobs error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
