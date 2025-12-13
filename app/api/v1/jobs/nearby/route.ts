import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { requireAuth } from '@/lib/middleware';
import { successResponse, errorResponse } from '@/lib/response';
import { getBoundingBox } from '@/lib/geo';
import { apiCache, CacheKeys, CacheTTL } from '@/lib/cache';

/**
 * Calculate distance between two coordinates using Haversine formula
 */
function calculateDistance(
    lat1: number, lon1: number,
    lat2: number, lon2: number
): number {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

/**
 * Get Nearby Available Jobs (OPTIMIZED)
 * GET /api/v1/jobs/nearby
 * 
 * Performance optimizations:
 * - Bounding box filtering at database level
 * - Response caching (5 second TTL)
 * - Composite indexes on status+bookingMode+expiresAt
 * - Limit results to 20 jobs
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

        // Get driver's current location from query params or user profile
        const { searchParams } = new URL(request.url);
        let lat = searchParams.get('lat');
        let lng = searchParams.get('lng');
        const radiusParam = searchParams.get('radius');
        const radius = radiusParam ? parseFloat(radiusParam) : 10; // Default 10km

        // If no lat/lng provided, get from user profile
        if (!lat || !lng) {
            const user = await prisma.user.findUnique({
                where: { id: authResult.userId },
                select: { currentLat: true, currentLng: true }
            });

            if (user?.currentLat && user?.currentLng) {
                lat = user.currentLat.toString();
                lng = user.currentLng.toString();
            } else {
                // Fallback to Lagos center if no location available
                // This allows drivers to see jobs even without precise location
                lat = '6.5244'; // Lagos, Nigeria latitude
                lng = '3.3792'; // Lagos, Nigeria longitude
                console.warn(`Driver ${authResult.userId} has no location. Using default Lagos coordinates.`);
            }
        }

        const driverLat = parseFloat(lat);
        const driverLng = parseFloat(lng);

        // Check cache first (5 second TTL)
        const cacheKey = CacheKeys.nearbyJobs(authResult.userId, driverLat, driverLng, radius);
        const cachedData = apiCache.get(cacheKey);

        if (cachedData) {
            return NextResponse.json(cachedData);
        }

        // Calculate bounding box for spatial filtering
        const bbox = getBoundingBox(driverLat, driverLng, radius);

        // Get all available jobs with OPTIMIZED query
        const now = new Date();
        const jobs = await prisma.job.findMany({
            where: {
                status: 'POSTED',
                // Show both AUTO_ACCEPT and BIDDING jobs
                // Bounding box filter (uses spatial index)
                pickupLat: { gte: bbox.minLat, lte: bbox.maxLat },
                pickupLng: { gte: bbox.minLng, lte: bbox.maxLng },
                OR: [
                    { expiresAt: null },
                    { expiresAt: { gt: now } },
                ],
            },
            include: {
                shipper: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        rating: true,
                    }
                },
                _count: {
                    select: { bids: true }
                }
            },
            take: 20, // Limit results for performance
            orderBy: {
                createdAt: 'desc'
            }
        });

        // Filter jobs by exact distance and enrich with distance and earnings info
        const platformFeePercent = Number(process.env.PLATFORM_FEE_PERCENT || 10);

        const nearbyJobs = jobs
            .map(job => {
                const distance = calculateDistance(
                    driverLat,
                    driverLng,
                    job.pickupLat,
                    job.pickupLng
                );

                // Calculate estimated earnings (price - platform fee)
                const platformFee = Math.round((job.computedPrice || 0) * (platformFeePercent / 100));
                const estimatedEarnings = (job.computedPrice || 0) - platformFee;

                // Calculate time until expiration
                let expiresInMinutes = null;
                if (job.expiresAt) {
                    const diffMs = job.expiresAt.getTime() - now.getTime();
                    expiresInMinutes = Math.max(0, Math.floor(diffMs / 60000));
                }

                return {
                    ...job,
                    distanceFromDriver: parseFloat(distance.toFixed(2)),
                    estimatedEarnings,
                    expiresInMinutes,
                };
            })
            .filter(job => job.distanceFromDriver <= radius)
            .sort((a, b) => a.distanceFromDriver - b.distanceFromDriver); // Sort by closest first

        const response = successResponse({
            jobs: nearbyJobs,
            count: nearbyJobs.length,
            radius: radius,
            driverLocation: { lat: driverLat, lng: driverLng }
        }, 'Nearby jobs retrieved successfully');

        // Cache the response for 5 seconds
        apiCache.set(cacheKey, response, CacheTTL.NEARBY_JOBS);

        return NextResponse.json(response);

    } catch (error: any) {
        console.error('Get nearby jobs error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
