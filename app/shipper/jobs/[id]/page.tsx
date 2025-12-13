'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

interface Bid {
    id: string;
    amount: number;
    etaMinutes: number;
    message: string;
    status: string;
    createdAt: string;
    carrier: {
        id: string;
        name: string;
        phone: string;
        rating: number;
        totalJobs: number;
    };
}

interface Job {
    id: string;
    pickupAddress: string;
    dropoffAddress: string;
    distanceKm: number;
    computedPrice: number;
    finalPrice?: number;
    status: string;
    cargoType: string;
    cargoWeight?: number;
    cargoDescription?: string;
    createdAt: string;
    acceptedAt?: string;
    acceptedBidId?: string;
    bids: Bid[];
    carrier?: {
        id: string;
        name: string;
        phone: string;
    };
}

export default function JobDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const [job, setJob] = useState<Job | null>(null);
    const [loading, setLoading] = useState(true);
    const [accepting, setAccepting] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        const token = localStorage.getItem('accessToken');
        if (!token) {
            router.push('/auth/login');
            return;
        }

        fetchJobDetails();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [params.id]);

    const fetchJobDetails = async () => {
        try {
            const token = localStorage.getItem('accessToken');

            // Fetch job details
            const jobResponse = await fetch(`/api/v1/jobs/${params.id}`, {
                headers: { Authorization: `Bearer ${token}` },
            });

            if (!jobResponse.ok) throw new Error('Failed to fetch job');
            const jobData = await jobResponse.json();

            // Fetch bids
            const bidsResponse = await fetch(`/api/v1/jobs/${params.id}/bids`, {
                headers: { Authorization: `Bearer ${token}` },
            });

            const bidsData = await bidsResponse.json();

            setJob({
                ...jobData.data,
                bids: bidsData.success ? bidsData.data : [],
            });
        } catch (error) {
            console.error('Error fetching job:', error);
            setError('Failed to load job details');
        } finally {
            setLoading(false);
        }
    };

    const handleAcceptBid = async (bidId: string) => {
        if (!confirm('Accept this bid? This cannot be undone.')) return;

        setAccepting(true);
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${params.id}/accept`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({ bidId }),
            });

            if (!response.ok) throw new Error('Failed to accept bid');

            await fetchJobDetails();
            alert('Bid accepted successfully!');
        } catch (error) {
            alert('Failed to accept bid');
        } finally {
            setAccepting(false);
        }
    };

    const getStatusColor = (status: string) => {
        const colors: Record<string, string> = {
            POSTED: 'bg-blue-100 text-blue-800',
            MATCHED: 'bg-green-100 text-green-800',
            IN_TRANSIT: 'bg-yellow-100 text-yellow-800',
            DELIVERED: 'bg-emerald-100 text-emerald-800',
            DISPUTED: 'bg-red-100 text-red-800',
            CANCELLED: 'bg-gray-100 text-gray-800',
        };
        return colors[status] || 'bg-gray-100 text-gray-800';
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-brand-green-500 border-t-transparent"></div>
            </div>
        );
    }

    if (!job) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-center">
                    <p className="text-gray-600 mb-4">Job not found</p>
                    <Link href="/shipper/dashboard" className="btn-primary">
                        Back to Dashboard
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white shadow-sm border-b border-gray-200">
                <div className="container mx-auto px-4 py-4 flex justify-between items-center">
                    <h1 className="text-2xl font-bold text-brand-green-500">Deliver4Me</h1>
                    <Link href="/shipper/dashboard" className="btn-secondary text-sm py-2">
                        ← Back to Dashboard
                    </Link>
                </div>
            </header>

            {/* Main Content */}
            <div className="container mx-auto px-4 py-8">
                <div className="max-w-4xl mx-auto space-y-6">
                    {/* Job Details Card */}
                    <div className="card">
                        <div className="flex justify-between items-start mb-4">
                            <div>
                                <h2 className="text-2xl font-bold text-gray-800 mb-2">{job.cargoType}</h2>
                                <span className={`status-chip ${getStatusColor(job.status)}`}>
                                    {job.status}
                                </span>
                            </div>
                            <div className="text-right">
                                <div className="text-3xl font-bold text-brand-green-600">
                                    ₦{(job.finalPrice || job.computedPrice)?.toLocaleString()}
                                </div>
                                <p className="text-sm text-gray-500">{job.distanceKm?.toFixed(1)} km</p>
                            </div>
                        </div>

                        <div className="space-y-3 border-t pt-4">
                            <div>
                                <p className="text-sm font-medium text-gray-700">Pickup Address</p>
                                <p className="text-gray-600">{job.pickupAddress}</p>
                            </div>
                            <div>
                                <p className="text-sm font-medium text-gray-700">Dropoff Address</p>
                                <p className="text-gray-600">{job.dropoffAddress}</p>
                            </div>
                            {job.cargoWeight && (
                                <div>
                                    <p className="text-sm font-medium text-gray-700">Weight</p>
                                    <p className="text-gray-600">{job.cargoWeight} kg</p>
                                </div>
                            )}
                            {job.cargoDescription && (
                                <div>
                                    <p className="text-sm font-medium text-gray-700">Description</p>
                                    <p className="text-gray-600">{job.cargoDescription}</p>
                                </div>
                            )}
                            <div>
                                <p className="text-sm font-medium text-gray-700">Posted</p>
                                <p className="text-gray-600">{new Date(job.createdAt).toLocaleString()}</p>
                            </div>
                            {job.carrier && (
                                <div className="bg-green-50 p-3 rounded-lg">
                                    <p className="text-sm font-medium text-gray-700">Assigned Carrier</p>
                                    <p className="text-gray-800 font-medium">{job.carrier.name}</p>
                                    <p className="text-sm text-gray-600">{job.carrier.phone}</p>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Bids Section */}
                    <div className="card">
                        <h3 className="text-xl font-bold text-gray-800 mb-4">
                            Bids ({job.bids.length})
                        </h3>

                        {job.bids.length === 0 ? (
                            <div className="text-center py-8 text-gray-500">
                                <p>No bids yet. Carriers will see your job and can place bids.</p>
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {job.bids.map((bid) => (
                                    <div
                                        key={bid.id}
                                        className={`border rounded-lg p-4 ${bid.id === job.acceptedBidId
                                            ? 'border-green-500 bg-green-50'
                                            : 'border-gray-200'
                                            }`}
                                    >
                                        <div className="flex justify-between items-start">
                                            <div className="flex-1">
                                                <div className="flex items-center gap-2 mb-2">
                                                    <h4 className="font-semibold text-gray-800">
                                                        {bid.carrier.name}
                                                    </h4>
                                                    {bid.carrier.rating > 0 && (
                                                        <span className="text-sm text-gray-600">
                                                            ⭐ {bid.carrier.rating.toFixed(1)}
                                                        </span>
                                                    )}
                                                    <span className="text-xs text-gray-500">
                                                        ({bid.carrier.totalJobs} jobs)
                                                    </span>
                                                    {bid.id === job.acceptedBidId && (
                                                        <span className="status-chip bg-green-100 text-green-800">
                                                            ACCEPTED
                                                        </span>
                                                    )}
                                                </div>
                                                {bid.message && (
                                                    <p className="text-sm text-gray-600 mb-2">{bid.message}</p>
                                                )}
                                                <p className="text-xs text-gray-500">
                                                    ETA: {bid.etaMinutes} minutes • Posted{' '}
                                                    {new Date(bid.createdAt).toLocaleDateString()}
                                                </p>
                                            </div>
                                            <div className="text-right ml-4">
                                                <div className="text-2xl font-bold text-brand-green-600">
                                                    ₦{bid.amount.toLocaleString()}
                                                </div>
                                                {job.status === 'POSTED' && !job.acceptedBidId && (
                                                    <button
                                                        onClick={() => handleAcceptBid(bid.id)}
                                                        disabled={accepting}
                                                        className="btn-primary text-sm mt-2"
                                                    >
                                                        {accepting ? 'Accepting...' : 'Accept Bid'}
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
