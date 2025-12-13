// lib/matching.ts
import { User, Vehicle } from '@prisma/client';
import { distanceBetween, clamp } from './geo';

interface Job {
    id: string;
    pickupLat: number;
    pickupLng: number;
    dropoffLat: number;
    dropoffLng: number;
    cargoWeight?: number | null;
    computedPrice?: number | null;
}

interface CarrierWithVehicle extends User {
    vehicles: Vehicle[];
    currentLocation?: { lat: number; lng: number };
}

const MAX_RADIUS = 50000; // 50km max radius

/**
 * Score a carrier for a specific job based on multiple factors
 * 
 * @param carrier - Carrier user with vehicles
 * @param job - Job to be matched
 * @param bidAmount - Bid amount from carrier
 * @returns Score between 0 and 1
 */
export function scoreCarrier(
    carrier: CarrierWithVehicle,
    job: Job,
    bidAmount?: number
): number {
    // Distance score (closer is better) - weight 0.4
    let distanceScore = 0;
    if (carrier.currentLocation) {
        const distance = distanceBetween(
            carrier.currentLocation,
            { lat: job.pickupLat, lng: job.pickupLng }
        );
        distanceScore = 1 - clamp(distance / MAX_RADIUS, 0, 1);
    }

    // Capacity score (matching capacity) - weight 0.25
    let capacityScore = 0;
    if (carrier.vehicles && carrier.vehicles.length > 0) {
        const maxCapacity = Math.max(...carrier.vehicles.map(v => v.capacityKg));
        const requiredCapacity = job.cargoWeight || 0;
        if (requiredCapacity > 0) {
            capacityScore = maxCapacity >= requiredCapacity ? 1 : maxCapacity / requiredCapacity;
        } else {
            capacityScore = 0.5; // Neutral if no weight specified
        }
    }

    // Rating score - weight 0.15
    const ratingScore = carrier.rating / 5;

    // Availability score (active user) - weight 0.1
    const availabilityScore = carrier.isActive ? 1 : 0;

    // Price score (bid competitive) - weight 0.1
    let priceScore = 0.5; // Default neutral
    if (bidAmount && job.computedPrice) {
        const priceDiff = Math.abs(bidAmount - job.computedPrice) / job.computedPrice;
        priceScore = 1 - Math.min(priceDiff, 1);
    }

    // Weighted sum
    return (
        0.4 * distanceScore +
        0.25 * capacityScore +
        0.15 * ratingScore +
        0.1 * availabilityScore +
        0.1 * priceScore
    );
}

/**
 * Find the best carrier match for a job
 * 
 * @param carriers - Array of carriers with bids
 * @param job - Job to match
 * @returns Best carrier or null
 */
export function findBestMatch(
    carriers: Array<{ carrier: CarrierWithVehicle; bidAmount: number }>,
    job: Job
): { carrier: CarrierWithVehicle; score: number } | null {
    if (carriers.length === 0) return null;

    const scored = carriers.map(({ carrier, bidAmount }) => ({
        carrier,
        score: scoreCarrier(carrier, job, bidAmount),
    }));

    // Sort by score descending
    scored.sort((a, b) => b.score - a.score);

    return scored[0];
}

/**
 * Filter carriers by radius and basic criteria
 * 
 * @param carriers - Array of carriers
 * @param jobLocation - Job pickup location
 * @param radiusKm - Search radius in kilometers
 * @returns Filtered carriers
 */
export function filterCarriersByRadius(
    carriers: CarrierWithVehicle[],
    jobLocation: { lat: number; lng: number },
    radiusKm: number = 50
): CarrierWithVehicle[] {
    return carriers.filter(carrier => {
        if (!carrier.currentLocation) return false;
        if (!carrier.isActive) return false;
        if (carrier.vehicles.length === 0) return false;

        const distance = distanceBetween(carrier.currentLocation, jobLocation);
        return distance <= radiusKm * 1000; // Convert to meters
    });
}
