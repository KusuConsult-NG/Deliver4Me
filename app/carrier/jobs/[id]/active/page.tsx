'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { MapPin, Package, Phone, User, Navigation, XCircle, CheckCircle } from 'lucide-react';

interface Job {
    id: string;
    pickupAddress: string;
    pickupLat: number;
    pickupLng: number;
    dropoffAddress: string;
    dropoffLat: number;
    dropoffLng: number;
    distanceKm: number;
    cargoType: string;
    cargoWeight?: number;
    cargoDescription?: string;
    finalPrice: number;
    status: string;
    shipper: {
        id: string;
        name: string;
        phone: string;
        rating: number;
    };
}

export default function ActiveJobPage() {
    const router = useRouter();
    const params = useParams();
    const jobId = params.id as string;

    const [job, setJob] = useState<Job | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    useEffect(() => {
        fetchJobDetails();
    }, []);

    const fetchJobDetails = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });

            if (response.ok) {
                const data = await response.json();
                setJob(data.data);
            } else {
                setError('Failed to load job details');
            }
        } catch (err) {
            setError('Failed to load job details');
        } finally {
            setLoading(false);
        }
    };

    const handleStartDelivery = async () => {
        setActionLoading(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
            });

            if (response.ok) {
                await fetchJobDetails();
            } else {
                setError('Failed to start delivery');
            }
        } catch (err) {
            setError('Failed to start delivery');
        } finally {
            setActionLoading(false);
        }
    };

    const handleCompleteDelivery = async () => {
        setActionLoading(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}/complete`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({}),
            });

            if (response.ok) {
                router.push('/carrier/dashboard?completed=true');
            } else {
                setError('Failed to complete delivery');
            }
        } catch (err) {
            setError('Failed to complete delivery');
        } finally {
            setActionLoading(false);
        }
    };

    const handleCancelJob = async () => {
        if (!confirm('Are you sure you want to cancel this delivery? This may affect your rating.')) {
            return;
        }

        setActionLoading(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}/cancel`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({
                    reason: 'Cancelled by driver',
                }),
            });

            if (response.ok) {
                router.push('/carrier/dashboard');
            } else {
                setError('Failed to cancel job');
            }
        } catch (err) {
            setError('Failed to cancel job');
        } finally {
            setActionLoading(false);
        }
    };

    const openInMaps = (lat: number, lng: number) => {
        window.open(`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`, '_blank');
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-4 border-brand-green-500 border-t-transparent"></div>
            </div>
        );
    }

    if (!job) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
                <div className="text-center">
                    <h2 className="text-xl font-bold text-gray-800 mb-2">Job not found</h2>
                    <button
                        onClick={() => router.push('/carrier/dashboard')}
                        className="btn-primary mt-4"
                    >
                        Back to Dashboard
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="bg-brand-green-500 text-white p-4 sticky top-0 z-10">
                <div className="max-w-2xl mx-auto flex items-center justify-between">
                    <button
                        onClick={() => router.push('/carrier/dashboard')}
                        className="text-white"
                    >
                        ← Back
                    </button>
                    <h1 className="text-xl font-bold">Active Delivery</h1>
                    <div className="w-16"></div>
                </div>
            </div>

            <div className="max-w-2xl mx-auto p-4 space-y-4">
                {error && (
                    <div className="bg-red-50 border border-red-200 rounded-xl p-3 text-red-700">
                        {error}
                    </div>
                )}

                <div className="bg-white rounded-2xl p-4 shadow-sm">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm text-gray-600">Status</p>
                            <p className="text-xl font-bold text-brand-green-600">{job.status}</p>
                        </div>
                        <div className="text-right">
                            <p className="text-sm text-gray-600">You earn</p>
                            <p className="text-2xl font-bold text-brand-green-600">
                                ₦{Math.round(job.finalPrice * 0.9).toLocaleString()}
                            </p>
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-2xl p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-3">
                        <Package className="w-5 h-5 text-gray-600" />
                        <h2 className="font-bold text-gray-800">Cargo Details</h2>
                    </div>
                    <div className="space-y-2">
                        <div className="flex justify-between">
                            <span className="text-gray-600">Type:</span>
                            <span className="font-semibold">{job.cargoType}</span>
                        </div>
                        {job.cargoWeight && (
                            <div className="flex justify-between">
                                <span className="text-gray-600">Weight:</span>
                                <span className="font-semibold">{job.cargoWeight} kg</span>
                            </div>
                        )}
                        {job.cargoDescription && (
                            <div>
                                <span className="text-gray-600">Description:</span>
                                <p className="text-sm mt-1">{job.cargoDescription}</p>
                            </div>
                        )}
                        <div className="flex justify-between">
                            <span className="text-gray-600">Distance:</span>
                            <span className="font-semibold">{job.distanceKm.toFixed(1)} km</span>
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-2xl p-4 shadow-sm">
                    <div className="flex items-start gap-3 mb-3">
                        <div className="w-3 h-3 rounded-full bg-brand-green-500 mt-1.5"></div>
                        <div className="flex-1">
                            <p className="text-sm text-gray-600 mb-1">Pickup Location</p>
                            <p className="font-medium text-gray-900">{job.pickupAddress}</p>
                        </div>
                    </div>
                    <button
                        onClick={() => openInMaps(job.pickupLat, job.pickupLng)}
                        className="w-full flex items-center justify-center gap-2 bg-blue-500 text-white py-3 rounded-xl font-semibold hover:bg-blue-600 transition-colors"
                    >
                        <Navigation className="w-5 h-5" />
                        Navigate to Pickup
                    </button>
                </div>

                <div className="bg-white rounded-2xl p-4 shadow-sm">
                    <div className="flex items-start gap-3 mb-3">
                        <div className="w-3 h-3 rounded-full bg-red-500 mt-1.5"></div>
                        <div className="flex-1">
                            <p className="text-sm text-gray-600 mb-1">Dropoff Location</p>
                            <p className="font-medium text-gray-900">{job.dropoffAddress}</p>
                        </div>
                    </div>
                    <button
                        onClick={() => openInMaps(job.dropoffLat, job.dropoffLng)}
                        className="w-full flex items-center justify-center gap-2 bg-purple-500 text-white py-3 rounded-xl font-semibold hover:bg-purple-600 transition-colors"
                    >
                        <Navigation className="w-5 h-5" />
                        Navigate to Dropoff
                    </button>
                </div>

                <div className="bg-white rounded-2xl p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-3">
                        <User className="w-5 h-5 text-gray-600" />
                        <h2 className="font-bold text-gray-800">Shipper Contact</h2>
                    </div>
                    <div className="space-y-2">
                        <div className="flex justify-between items-center">
                            <span className="text-gray-600">Name:</span>
                            <span className="font-semibold">{job.shipper.name}</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span className="text-gray-600">Rating:</span>
                            <span className="font-semibold">⭐ {job.shipper.rating.toFixed(1)}</span>
                        </div>
                    </div>
                    <a
                        href={`tel:${job.shipper.phone}`}
                        className="w-full flex items-center justify-center gap-2 bg-brand-green-500 text-white py-3 rounded-xl font-semibold hover:bg-brand-green-600 transition-colors mt-3"
                    >
                        <Phone className="w-5 h-5" />
                        Call Shipper
                    </a>
                </div>

                <div className="space-y-3">
                    {job.status === 'MATCHED' && (
                        <>
                            <button
                                onClick={handleStartDelivery}
                                disabled={actionLoading}
                                className="w-full flex items-center justify-center gap-2 bg-brand-green-500 text-white py-4 rounded-xl font-bold text-lg hover:bg-brand-green-600 transition-colors disabled:opacity-50"
                            >
                                <CheckCircle className="w-6 h-6" />
                                {actionLoading ? 'Starting...' : 'Start Delivery'}
                            </button>
                            <button
                                onClick={handleCancelJob}
                                disabled={actionLoading}
                                className="w-full flex items-center justify-center gap-2 bg-red-500 text-white py-3 rounded-xl font-semibold hover:bg-red-600 transition-colors disabled:opacity-50"
                            >
                                <XCircle className="w-5 h-5" />
                                {actionLoading ? 'Cancelling...' : 'Cancel Delivery'}
                            </button>
                        </>
                    )}

                    {job.status === 'IN_TRANSIT' && (
                        <button
                            onClick={handleCompleteDelivery}
                            disabled={actionLoading}
                            className="w-full flex items-center justify-center gap-2 bg-brand-green-500 text-white py-4 rounded-xl font-bold text-lg hover:bg-brand-green-600 transition-colors disabled:opacity-50"
                        >
                            <CheckCircle className="w-6 h-6" />
                            {actionLoading ? 'Completing...' : 'Complete Delivery'}
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
}
