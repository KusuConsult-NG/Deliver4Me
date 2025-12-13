// components/LoadingSkeleton.tsx
/**
 * Reusable loading skeleton components
 * Better UX than spinners - shows content structure while loading
 */

export function JobCardSkeleton() {
    return (
        <div className="bg-white border-2 border-gray-200 rounded-2xl p-4 animate-pulse">
            {/* Header */}
            <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2 flex-1">
                    <div className="w-5 h-5 bg-gray-200 rounded"></div>
                    <div className="w-24 h-5 bg-gray-200 rounded"></div>
                </div>
                <div className="text-right">
                    <div className="w-20 h-8 bg-gray-200 rounded mb-1"></div>
                </div>
            </div>

            {/* Addresses */}
            <div className="space-y-2 mb-3">
                <div className="flex items-start gap-2">
                    <div className="w-2 h-2 rounded-full bg-gray-200 mt-2"></div>
                    <div className="flex-1">
                        <div className="w-16 h-3 bg-gray-200 rounded mb-1"></div>
                        <div className="w-full h-4 bg-gray-200 rounded"></div>
                    </div>
                </div>
                <div className="w-0.5 h-4 bg-gray-200 ml-1"></div>
                <div className="flex items-start gap-2">
                    <div className="w-2 h-2 rounded-full bg-gray-200 mt-2"></div>
                    <div className="flex-1">
                        <div className="w-16 h-3 bg-gray-200 rounded mb-1"></div>
                        <div className="w-full h-4 bg-gray-200 rounded"></div>
                    </div>
                </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-4">
                    <div className="w-16 h-4 bg-gray-200 rounded"></div>
                    <div className="w-20 h-4 bg-gray-200 rounded"></div>
                </div>
                <div className="w-12 h-4 bg-gray-200 rounded"></div>
            </div>
        </div>
    );
}

export function DashboardHeaderSkeleton() {
    return (
        <div className="bg-brand-green-500 text-white p-4">
            <div className="max-w-2xl mx-auto">
                <div className="flex items-center justify-between mb-4">
                    <div className="w-40 h-8 bg-white bg-opacity-20 rounded"></div>
                    <div className="flex items-center gap-3">
                        <div className="w-20 h-12 bg-white bg-opacity-20 rounded-xl"></div>
                        <div className="w-24 h-10 bg-white bg-opacity-30 rounded-full"></div>
                    </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                    <div className="bg-white bg-opacity-20 rounded-xl p-3">
                        <div className="w-32 h-4 bg-white bg-opacity-30 rounded mb-2"></div>
                        <div className="w-24 h-8 bg-white bg-opacity-40 rounded"></div>
                    </div>
                    <div className="bg-white bg-opacity-20 rounded-xl p-3">
                        <div className="w-28 h-4 bg-white bg-opacity-30 rounded mb-2"></div>
                        <div className="w-16 h-8 bg-white bg-opacity-40 rounded"></div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export function StatsCardSkeleton() {
    return (
        <div className="card bg-gradient-to-br from-gray-50 to-white animate-pulse">
            <div className="w-24 h-4 bg-gray-200 rounded mb-2"></div>
            <div className="w-16 h-10 bg-gray-200 rounded mb-1"></div>
            <div className="w-20 h-3 bg-gray-200 rounded"></div>
        </div>
    );
}

export function JobListSkeleton({ count = 3 }: { count?: number }) {
    return (
        <div className="space-y-3">
            {Array.from({ length: count }).map((_, i) => (
                <JobCardSkeleton key={i} />
            ))}
        </div>
    );
}

export function FullPageSkeleton() {
    return (
        <div className="min-h-screen bg-gray-50">
            <DashboardHeaderSkeleton />
            <div className="max-w-2xl mx-auto px-4 py-6">
                <div className="flex items-center justify-between mb-4">
                    <div className="w-40 h-6 bg-gray-200 rounded animate-pulse"></div>
                    <div className="w-20 h-6 bg-gray-200 rounded animate-pulse"></div>
                </div>
                <JobListSkeleton count={3} />
            </div>
        </div>
    );
}
