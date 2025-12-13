'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { MapPin, Package, Clock, User, ArrowRight } from 'lucide-react';

interface Job {
    id: string;
    pickupAddress: string;
    dropoffAddress: string;
    distanceKm: number;
    cargoType: string;
    cargoWeight?: number;
    computedPrice?: number;
    createdAt: string;
    shipper: {
        name: string;
        rating: number;
    };
}

export default function AcceptDeliveryPage() {
    const router = useRouter();
    const params = useParams();
    const jobId = params?.id as string;

    const [job, setJob] = useState<Job | null>(null);
    const [loading, setLoading] = useState(true);
    const [accepting, setAccepting] = useState(false);
    const [showCounterOffer, setShowCounterOffer] = useState(false);
    const [counterAmount, setCounterAmount] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        fetchJobDetails();
    }, [jobId]);

    const fetchJobDetails = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });

            if (!response.ok) throw new Error('Failed to load delivery');

            const data = await response.json();
            setJob(data.data);
            if (data.data.computedPrice) {
                setCounterAmount(data.data.computedPrice.toString());
            }
        } catch (err: any) {
            setError(err.message || 'Failed to load delivery');
        } finally {
            setLoading(false);
        }
    };

    const handleAccept = async (amount: number) => {
        setAccepting(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${jobId}/bids`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({ amount }),
            });

            const data = await response.json();
            if (!response.ok) throw new Error(data.error || 'Failed to accept delivery');

            router.push('/carrier/dashboard');
        } catch (err: any) {
            setError(err.message || 'Failed to accept delivery');
        } finally {
            setAccepting(false);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-white flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-16 w-16 border-4 border-brand-green-500 border-t-transparent mx-auto"></div>
                    <p className="mt-4 text-gray-600 text-lg">Loading delivery...</p>
                </div>
            </div>
        );
    }

    if (!job) {
        return (
            <div className="min-h-screen bg-white flex items-center justify-center p-4">
                <div className="text-center max-w-sm">
                    <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Package className="w-10 h-10 text-gray-400" />
                    </div>
                    <h1 className="text-2xl font-bold text-gray-800 mb-2">Delivery Not Found</h1>
                    <p className="text-gray-600 mb-6">This delivery is no longer available</p>
                    <button
                        onClick={() => router.push('/carrier/dashboard')}
                        className="bg-brand-green-500 text-white px-8 py-3 rounded-xl font-semibold text-lg w-full"
                    >
                        Find Deliveries
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-white">
            {/* Top Bar */}
            <div className="bg-white border-b sticky top-0 z-10">
                <div className="max-w-2xl mx-auto px-4 py-4">
                    <button
                        onClick={() => router.push('/carrier/dashboard')}
                        className="text-gray-600 font-medium"
                    >
                        ✕ Cancel
                    </button>
                </div>
            </div>

            <div className="max-w-2xl mx-auto px-4 py-6 pb-32">
                {/* Route Card */}
                <div className="bg-gray-50 rounded-2xl p-6 mb-4">
                    {/* Pickup */}
                    <div className="flex items-start mb-4">
                        <div className="w-3 h-3 rounded-full bg-brand-green-500 mt-2 mr-4 flex-shrink-0"></div>
                        <div className="flex-1">
                            <p className="text-sm text-gray-500 mb-1">Pickup</p>
                            <p className="text-lg font-semibold text-gray-900">{job.pickupAddress}</p>
                        </div>
                    </div>

                    {/* Vertical Line */}
                    <div className="w-0.5 h-8 bg-gray-300 ml-1.5 mb-4"></div>

                    {/* Dropoff */}
                    <div className="flex items-start">
                        <div className="w-3 h-3 rounded-full bg-red-500 mt-2 mr-4 flex-shrink-0"></div>
                        <div className="flex-1">
                            <p className="text-sm text-gray-500 mb-1">Dropoff</p>
                            <p className="text-lg font-semibold text-gray-900">{job.dropoffAddress}</p>
                        </div>
                    </div>
                </div>

                {/* Delivery Info */}
                <div className="grid grid-cols-3 gap-3 mb-6">
                    <div className="bg-gray-50 rounded-xl p-4 text-center">
                        <MapPin className="w-6 h-6 text-gray-600 mx-auto mb-2" />
                        <p className="text-2xl font-bold text-gray-900">{job.distanceKm?.toFixed(1)}</p>
                        <p className="text-xs text-gray-500">km</p>
                    </div>
                    <div className="bg-gray-50 rounded-xl p-4 text-center">
                        <Package className="w-6 h-6 text-gray-600 mx-auto mb-2" />
                        <p className="text-sm font-bold text-gray-900">{job.cargoType}</p>
                        {job.cargoWeight && (
                            <p className="text-xs text-gray-500">{job.cargoWeight}kg</p>
                        )}
                    </div>
                    <div className="bg-gray-50 rounded-xl p-4 text-center">
                        <User className="w-6 h-6 text-gray-600 mx-auto mb-2" />
                        <p className="text-sm font-bold text-gray-900">{job.shipper.name.split(' ')[0]}</p>
                        <p className="text-xs text-gray-500">⭐ {job.shipper.rating.toFixed(1)}</p>
                    </div>
                </div>

                {/* Error Message */}
                {error && (
                    <div className="bg-red-50 border border-red-200 rounded-xl p-4 mb-4">
                        <p className="text-red-700 text-center font-medium">{error}</p>
                    </div>
                )}

                {/* Pricing Section */}
                {!showCounterOffer ? (
                    <>
                        {/* Suggested Price */}
                        <div className="bg-gradient-to-r from-brand-green-500 to-brand-green-600 rounded-2xl p-6 mb-4 text-white text-center">
                            <p className="text-sm opacity-90 mb-2">You'll Earn</p>
                            <p className="text-5xl font-bold mb-1">₦{job.computedPrice?.toLocaleString()}</p>
                            <p className="text-sm opacity-75">for {job.distanceKm?.toFixed(1)}km delivery</p>
                        </div>

                        {/* Action Buttons */}
                        <button
                            onClick={() => handleAccept(job.computedPrice || 0)}
                            disabled={accepting}
                            className="w-full bg-brand-green-500 hover:bg-brand-green-600 text-white py-4 rounded-xl font-bold text-lg mb-3 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
                        >
                            {accepting ? 'Accepting...' : 'Accept Delivery'}
                        </button>

                        <button
                            onClick={() => setShowCounterOffer(true)}
                            className="w-full bg-white border-2 border-gray-300 text-gray-700 py-4 rounded-xl font-semibold text-lg"
                        >
                            Make Counter Offer
                        </button>
                    </>
                ) : (
                    <>
                        {/* Counter Offer Input */}
                        <div className="mb-4">
                            <label className="block text-sm font-medium text-gray-700 mb-3 text-center">
                                Your Price (₦)
                            </label>
                            <input
                                type="number"
                                value={counterAmount}
                                onChange={(e) => setCounterAmount(e.target.value)}
                                className="w-full text-4xl font-bold text-center border-2 border-gray-300 rounded-xl py-4 focus:border-brand-green-500 focus:outline-none"
                                placeholder="0"
                                min="100"
                                step="50"
                            />
                            <p className="text-sm text-gray-500 text-center mt-2">
                                Suggested: ₦{job.computedPrice?.toLocaleString()}
                            </p>
                        </div>

                        {/* Counter Offer Buttons */}
                        <button
                            onClick={() => handleAccept(parseInt(counterAmount))}
                            disabled={accepting || !counterAmount || parseInt(counterAmount) < 100}
                            className="w-full bg-brand-green-500 hover:bg-brand-green-600 text-white py-4 rounded-xl font-bold text-lg mb-3 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
                        >
                            {accepting ? 'Submitting...' : `Offer ₦${parseInt(counterAmount || '0').toLocaleString()}`}
                        </button>

                        <button
                            onClick={() => setShowCounterOffer(false)}
                            className="w-full bg-white border-2 border-gray-300 text-gray-700 py-4 rounded-xl font-semibold text-lg"
                        >
                            Cancel
                        </button>
                    </>
                )}
            </div>
        </div>
    );
}
