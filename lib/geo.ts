// lib/geo.ts - Add bounding box calculation
import { z } from 'zod';

/**
 * Calculate bounding box for spatial queries
 * Returns min/max lat/lng coordinates for a radius around a point
 */
export function getBoundingBox(
    lat: number,
    lng: number,
    radiusKm: number
): {
    minLat: number;
    maxLat: number;
    minLng: number;
    maxLng: number;
} {
    // Earth's radius in km
    const R = 6371;

    // Convert radius from km to radians
    const radLat = radiusKm / R;
    const radLng = radiusKm / (R * Math.cos(lat * Math.PI / 180));

    // Calculate bounds
    const minLat = lat - (radLat * 180 / Math.PI);
    const maxLat = lat + (radLat * 180 / Math.PI);
    const minLng = lng - (radLng * 180 / Math.PI);
    const maxLng = lng + (radLng * 180 / Math.PI);

    return {
        minLat: Math.max(minLat, -90),
        maxLat: Math.min(maxLat, 90),
        minLng: Math.max(minLng, -180),
        maxLng: Math.min(maxLng, 180),
    };
}

/**
 * Haversine formula to calculate distance between two points
 * @param point1 - First coordinate {lat, lng}
 * @param point2 - Second coordinate {lat, lng}
 * @returns Distance in meters
 */
export function distanceBetween(
    point1: { lat: number; lng: number },
    point2: { lat: number; lng: number }
): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = (point1.lat * Math.PI) / 180;
    const φ2 = (point2.lat * Math.PI) / 180;
    const Δφ = ((point2.lat - point1.lat) * Math.PI) / 180;
    const Δλ = ((point2.lng - point1.lng) * Math.PI) / 180;

    const a =
        Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in meters
}

/**
 * Clamp a number between min and max values
 */
export function clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
}

/**
 * Calculate routing distance between two points
 * In production, use Google Maps Distance Matrix API
 * For now, uses straight-line distance with congestion factor
 */
export async function calculateRoutingDistance(
    fromLat: number,
    fromLng: number,
    toLat: number,
    toLng: number
): Promise<number> {
    const straightLine = distanceBetween(
        { lat: fromLat, lng: fromLng },
        { lat: toLat, lng: toLng }
    );

    // Apply congestion factor (1.3x for urban areas)
    const routingDistance = straightLine * 1.3;

    // Convert to kilometers
    return routingDistance / 1000;
}
