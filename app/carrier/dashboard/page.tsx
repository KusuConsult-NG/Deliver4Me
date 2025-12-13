'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Package, MapPin, TrendingUp, DollarSign, Clock, AlertCircle } from 'lucide-react';

interface Job {
    id: string;
    pickupAddress: string;
    dropoffAddress: string;
    distanceKm: number;
    cargoType: string;
    cargoWeight?: number;
    computedPrice?: number;
    estimatedEarnings?: number;
    distanceFromDriver?: number;
    expiresInMinutes?: number | null;
    shipper: {
        name: string;
        rating: number;
    };
    _count: {
        bids: number;
    };
}

interface DriverStatus {
    isOnline: boolean;
    todayEarnings: number;
    todayDeliveries: number;
    rating: number;
}

export default function CarrierDashboard() {
    const router = useRouter();
    const [jobs, setJobs] = useState<Job[]>([]);
    const [driverStatus, setDriverStatus] = useState<DriverStatus | null>(null);
    const [loading, setLoading] = useState(true);
    const [toggling, setToggling] = useState(false);
    const [acceptingJobId, setAcceptingJobId] = useState<string | null>(null);
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');

    useEffect(() => {
        fetchDriverStatus();
        fetchNearbyJobs();

        // Refresh jobs every 10 seconds when online
        const interval = setInterval(() => {
            if (driverStatus?.isOnline) {
                fetchNearbyJobs();
            }
        }, 10000);

        return () => clearInterval(interval);
    }, [driverStatus?.isOnline]);

    const fetchDriverStatus = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch('/api/v1/driver/status', {
                headers: { 'Authorization': `Bearer ${token}` },
            });

            if (response.ok) {
                const data = await response.json();
                setDriverStatus(data.data);
            }
        } catch (err) {
            console.error('Failed to fetch status:', err);
        }
    };

    const fetchNearbyJobs = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            // Try to get current location
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    async (position) => {
                        const { latitude, longitude } = position.coords;
                        const response = await fetch(
                            `/api/v1/jobs/nearby?lat=${latitude}&lng=${longitude}&radius=10`,
                            { headers: { 'Authorization': `Bearer ${token}` } }
                        );

                        if (response.ok) {
                            const data = await response.json();
                            setJobs(data.data.jobs || []);
                        }
                        setLoading(false);
                    },
                    async () => {
                        // Fallback if location denied
                        const response = await fetch('/api/v1/jobs/nearby', {
                            headers: { 'Authorization': `Bearer ${token}` },
                        });
                        if (response.ok) {
                            const data = await response.json();
                            setJobs(data.data.jobs || []);
                        }
                        setLoading(false);
                    }
                );
            }
        } catch (err) {
            console.error('Failed to fetch jobs:', err);
            setLoading(false);
        }
    };

    const toggleOnlineStatus = async () => {
        setToggling(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');

            // Get current location if going online
            let latitude, longitude;
            if (!driverStatus?.isOnline && navigator.geolocation) {
                try {
                    const position = await new Promise<GeolocationPosition>((resolve, reject) => {
                        navigator.geolocation.getCurrentPosition(resolve, reject, {
                            timeout: 5000,
                            maximumAge: 60000,
                        });
                    });
                    latitude = position.coords.latitude;
                    longitude = position.coords.longitude;
                } catch (geoError) {
                    console.warn('Could not get location:', geoError);
                    // Continue without location - user can still go online
                    // Location will be requested again when fetching nearby jobs
                }
            }

            const response = await fetch('/api/v1/driver/status', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({
                    isOnline: !driverStatus?.isOnline,
                    latitude,
                    longitude,
                }),
            });

            if (response.ok) {
                const data = await response.json();
                setDriverStatus(data.data);
                if (data.data.isOnline) {
                    if (!latitude || !longitude) {
                        setError('ℹ️ Using approximate location. Enable GPS for more accurate job matches.');
                        // Clear info message after 5 seconds
                        setTimeout(() => setError(''), 5000);
                    }
                    fetchNearbyJobs(); // Refresh jobs when going online
                }
            } else {
                setError('Failed to toggle status');
            }
        } catch (err: any) {
            setError(err.message || 'Failed to toggle status');
        } finally {
            setToggling(false);
        }
    };

    const handleInstantAccept = async (jobId: string) => {
        setAcceptingJobId(jobId);
        setError('');
        setSuccessMessage('');

        try {
            const token = localStorage.getItem('accessToken');

            // Get current location
            let latitude, longitude;
            if (navigator.geolocation) {
                const position = await new Promise<GeolocationPosition>((resolve, reject) => {
                    navigator.geolocation.getCurrentPosition(resolve, reject);
                });
                latitude = position.coords.latitude;
                longitude = position.coords.longitude;
            }

            const response = await fetch(`/api/v1/jobs/${jobId}/instant-accept`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({ latitude, longitude }),
            });

            const data = await response.json();

            if (response.ok) {
                // Success! Navigate to job details
                setSuccessMessage('🎉 Job accepted! Navigating to details...');
                setTimeout(() => {
                    router.push(`/carrier/jobs/${jobId}/active`);
                }, 1000);
            } else {
                // Handle specific errors
                if (response.status === 409) {
                    setError('⚡ This job was just accepted by another driver');
                } else if (response.status === 410) {
                    setError('⏰ This job has expired');
                } else {
                    setError(data.message || 'Failed to accept job');
                }
                // Refresh jobs to remove the accepted/expired job
                fetchNearbyJobs();
            }
        } catch (err: any) {
            setError(err.message || 'Failed to accept job');
        } finally {
            setAcceptingJobId(null);
        }
    };

    return (
        <div className="min-h-screen bg-white">
            {/* Header */}
            <div className="bg-brand-green-500 text-white p-4 sticky top-0 z-10">
                <div className="max-w-2xl mx-auto">
                    <div className="flex items-center justify-between mb-4">
                        <h1 className="text-2xl font-bold">DeliverMe Driver</h1>
                        <div className="flex items-center gap-3">
                            <div className="text-right">
                                <p className="text-sm opacity-90">
                                    {driverStatus?.isOnline ? '🟢 Online' : '⚫ Offline'}
                                </p>
                                <p className="text-xs opacity-75">
                                    ⭐ {(driverStatus?.rating ?? 0).toFixed(1)}
                                </p>
                            </div>
                            <button
                                onClick={toggleOnlineStatus}
                                disabled={toggling}
                                className={`px-5 py-2 rounded-full font-semibold text-sm transition-all ${driverStatus?.isOnline
                                    ? 'bg-white text-brand-green-600'
                                    : 'bg-gray-700 text-white'
                                    } disabled:opacity-50`}
                            >
                                {toggling ? '...' : driverStatus?.isOnline ? 'Go Offline' : 'Go Online'}
                            </button>
                        </div>
                    </div>

                    {/* Today's Stats */}
                    <div className="grid grid-cols-2 gap-3">
                        <div className="bg-white bg-opacity-20 rounded-xl p-3">
                            <div className="flex items-center gap-2 text-sm opacity-90 mb-1">
                                <DollarSign className="w-4 h-4" />
                                <span>Today's Earnings</span>
                            </div>
                            <p className="text-2xl font-bold">
                                ₦{driverStatus?.todayEarnings.toLocaleString() || 0}
                            </p>
                        </div>
                        <div className="bg-white bg-opacity-20 rounded-xl p-3">
                            <div className="flex items-center gap-2 text-sm opacity-90 mb-1">
                                <TrendingUp className="w-4 h-4" />
                                <span>Deliveries</span>
                            </div>
                            <p className="text-2xl font-bold">
                                {driverStatus?.todayDeliveries || 0}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Alert Messages */}
            {error && (
                <div className="max-w-2xl mx-auto px-4 mt-4">
                    <div className="bg-red-50 border border-red-200 rounded-xl p-3 text-red-700 text-center">
                        {error}
                    </div>
                </div>
            )}

            {successMessage && (
                <div className="max-w-2xl mx-auto px-4 mt-4">
                    <div className="bg-green-50 border border-green-200 rounded-xl p-3 text-green-700 text-center">
                        {successMessage}
                    </div>
                </div>
            )}

            {/* Main Content */}
            <div className="max-w-2xl mx-auto px-4 py-6">
                {!driverStatus?.isOnline ? (
                    <div className="text-center py-16">
                        <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <Package className="w-12 h-12 text-gray-400" />
                        </div>
                        <h2 className="text-2xl font-bold text-gray-800 mb-2">You're Offline</h2>
                        <p className="text-gray-600 mb-6">
                            Go online to start receiving delivery requests
                        </p>
                        <button
                            onClick={toggleOnlineStatus}
                            className="bg-brand-green-500 text-white px-8 py-3 rounded-xl font-semibold text-lg shadow-lg"
                        >
                            Go Online Now
                        </button>
                    </div>
                ) : (
                    <>
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-gray-800">
                                Available Deliveries {jobs.length > 0 && `(${jobs.length})`}
                            </h2>
                            <button
                                onClick={fetchNearbyJobs}
                                className="text-brand-green-600 font-medium text-sm"
                            >
                                🔄 Refresh
                            </button>
                        </div>

                        {loading ? (
                            <div className="text-center py-12">
                                <div className="animate-spin rounded-full h-12 w-12 border-4 border-brand-green-500 border-t-transparent mx-auto"></div>
                                <p className="mt-4 text-gray-600">Loading deliveries...</p>
                            </div>
                        ) : jobs.length === 0 ? (
                            <div className="text-center py-12">
                                <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                    <Package className="w-10 h-10 text-gray-400" />
                                </div>
                                <h3 className="text-lg font-semibold text-gray-800 mb-2">No Deliveries Available</h3>
                                <p className="text-gray-600">
                                    We'll notify you when new jobs are posted nearby
                                </p>
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {jobs.map(job => (
                                    <div
                                        key={job.id}
                                        className="bg-white border-2 border-gray-200 rounded-2xl p-4 hover:border-brand-green-500 transition-all"
                                    >
                                        <div className="flex items-start justify-between mb-3">
                                            <div className="flex items-center gap-2">
                                                <Package className="w-5 h-5 text-gray-600" />
                                                <span className="font-semibold text-gray-900">{job.cargoType}</span>
                                                {job.cargoWeight && (
                                                    <span className="text-sm text-gray-500">• {job.cargoWeight}kg</span>
                                                )}
                                            </div>
                                            <div className="text-right">
                                                <p className="text-xs text-gray-500">You earn</p>
                                                <p className="text-2xl font-bold text-brand-green-600">
                                                    ₦{job.estimatedEarnings?.toLocaleString()}
                                                </p>
                                            </div>
                                        </div>

                                        <div className="space-y-2 mb-3">
                                            <div className="flex items-start gap-2">
                                                <div className="w-2 h-2 rounded-full bg-brand-green-500 mt-2 flex-shrink-0"></div>
                                                <div className="flex-1">
                                                    <p className="text-xs text-gray-500">Pickup</p>
                                                    <p className="text-sm font-medium text-gray-900 line-clamp-1">
                                                        {job.pickupAddress}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="w-0.5 h-4 bg-gray-300 ml-1"></div>
                                            <div className="flex items-start gap-2">
                                                <div className="w-2 h-2 rounded-full bg-red-500 mt-2 flex-shrink-0"></div>
                                                <div className="flex-1">
                                                    <p className="text-xs text-gray-500">Dropoff</p>
                                                    <p className="text-sm font-medium text-gray-900 line-clamp-1">
                                                        {job.dropoffAddress}
                                                    </p>
                                                </div>
                                            </div>
                                        </div>

                                        <div className="flex items-center justify-between text-sm mb-3">
                                            <div className="flex items-center gap-4 text-gray-600">
                                                <span>📍 {job.distanceKm?.toFixed(1)}km trip</span>
                                                {job.distanceFromDriver && (
                                                    <span>🚗 {job.distanceFromDriver.toFixed(1)}km away</span>
                                                )}
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <span className="text-yellow-500">⭐</span>
                                                <span className="font-medium">{job.shipper.rating.toFixed(1)}</span>
                                            </div>
                                        </div>

                                        {/* Expiration Timer */}
                                        {job.expiresInMinutes !== null && job.expiresInMinutes !== undefined && (
                                            <div className="flex items-center gap-1 text-xs text-orange-600 mb-3">
                                                <Clock className="w-3 h-3" />
                                                <span>Expires in {job.expiresInMinutes} min</span>
                                            </div>
                                        )}

                                        {/* Accept Button */}
                                        <button
                                            onClick={() => handleInstantAccept(job.id)}
                                            disabled={acceptingJobId === job.id}
                                            className="w-full bg-brand-green-500 text-white py-3 rounded-xl font-bold text-lg hover:bg-brand-green-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                        >
                                            {acceptingJobId === job.id ? (
                                                <span className="flex items-center justify-center gap-2">
                                                    <div className="animate-spin rounded-full h-5 w-5 border-2 border-white border-t-transparent"></div>
                                                    Accepting...
                                                </span>
                                            ) : (
                                                '✅ ACCEPT DELIVERY'
                                            )}
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </>
                )}
            </div>
        </div>
    );
}
