// lib/cache.ts
/**
 * Simple in-memory cache for API responses
 * Use Redis in production for multi-instance deployments
 */

interface CacheEntry<T> {
    data: T;
    expiresAt: number;
}

class SimpleCache {
    private cache = new Map<string, CacheEntry<any>>();
    private cleanupInterval: NodeJS.Timeout;

    constructor() {
        // Clean up expired entries every minute
        this.cleanupInterval = setInterval(() => {
            this.cleanup();
        }, 60000);
    }

    set<T>(key: string, data: T, ttlMs: number): void {
        this.cache.set(key, {
            data,
            expiresAt: Date.now() + ttlMs,
        });
    }

    get<T>(key: string): T | null {
        const entry = this.cache.get(key);

        if (!entry) {
            return null;
        }

        if (Date.now() > entry.expiresAt) {
            this.cache.delete(key);
            return null;
        }

        return entry.data as T;
    }

    delete(key: string): void {
        this.cache.delete(key);
    }

    clear(): void {
        this.cache.clear();
    }

    private cleanup(): void {
        const now = Date.now();
        for (const [key, entry] of this.cache.entries()) {
            if (now > entry.expiresAt) {
                this.cache.delete(key);
            }
        }
    }

    getStats() {
        return {
            size: this.cache.size,
            keys: Array.from(this.cache.keys()),
        };
    }
}

// Singleton instance
export const apiCache = new SimpleCache();

/**
 * Cache key generators for consistent naming
 */
export const CacheKeys = {
    nearbyJobs: (driverId: string, lat: number, lng: number, radius: number) =>
        `nearby:${driverId}:${lat.toFixed(3)}:${lng.toFixed(3)}:${radius}`,

    driverStatus: (driverId: string) =>
        `driver:status:${driverId}`,

    job: (jobId: string) =>
        `job:${jobId}`,
};

/**
 * TTL constants (in milliseconds)
 */
export const CacheTTL = {
    NEARBY_JOBS: 5000,      // 5 seconds - balance between freshness and performance
    DRIVER_STATUS: 30000,   // 30 seconds
    JOB_DETAILS: 10000,     // 10 seconds
};
