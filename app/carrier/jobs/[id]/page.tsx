'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

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
    shipper: {
        id: string;
        name: string;
        rating: number;
    };
}

export default function CarrierJobDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const [job, setJob] = useState<Job | null>(null);
    const [loading, setLoading] = useState(true);
    const [bidAmount, setBidAmount] = useState('');
    const [bidEta, setBidEta] = useState('');
    const [bidMessage, setBidMessage] = useState('');
    const [submitting, setSubmitting] = useState(false);
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
            const response = await fetch(`/api/v1/jobs/${params.id}`, {
                headers: { Authorization: `Bearer ${token}` },
            });

            if (!response.ok) throw new Error('Failed to fetch job');
            const data = await response.json();
            setJob(data.data);

            // Set default bid amount to computed price
            setBidAmount(data.data.computedPrice?.toString() || '');
        } catch (error) {
            console.error('Error fetching job:', error);
            setError('Failed to load job details');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitBid = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        setError('');

        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch(`/api/v1/jobs/${params.id}/bids`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    amount: parseInt(bidAmount),
                    etaMinutes: parseInt(bidEta),
                    message: bidMessage,
                }),
            });

            if (!response.ok) throw new Error('Failed to submit bid');

            alert('Bid submitted successfully!');
            router.push('/carrier/dashboard');
        } catch (error: any) {
            setError(error.message || 'Failed to submit bid');
        } finally {
            setSubmitting(false);
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
                    <Link href="/carrier/dashboard" className="btn-primary">
                        Back to Dashboard
                    </Link>
                </div>
            </div>
        );
    }

    const canBid = job.status === 'POSTED';

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white shadow-sm border-b border-gray-200">
                <div className="container mx-auto px-4 py-4 flex justify-between items-center">
                    <h1 className="text-2xl font-bold text-brand-green-500">Deliver4Me</h1>
                    <Link href="/carrier/dashboard" className="btn-secondary text-sm py-2">
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
                                <div className="text-sm text-gray-600 mb-1">Suggested Price</div>
                                <div className="text-3xl font-bold text-brand-green-600">
                                    ₦{job.computedPrice?.toLocaleString()}
                                </div>
                                <p className="text-sm text-gray-500">{job.distanceKm?.toFixed(1)} km</p>
                            </div>
                        </div>

                        <div className="space-y-3 border-t pt-4">
                            <div className="bg-blue-50 p-3 rounded-lg">
                                <p className="text-sm font-medium text-gray-700">Shipper</p>
                                <p className="text-gray-800 font-medium">{job.shipper.name}</p>
                                {job.shipper.rating > 0 && (
                                    <p className="text-sm text-gray-600">⭐ {job.shipper.rating.toFixed(1)}</p>
                                )}
                            </div>
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
                        </div>
                    </div>

                    {/* Bid Form */}
                    {canBid && (
                        <div className="card">
                            <h3 className="text-xl font-bold text-gray-800 mb-4">Place Your Bid</h3>

                            {error && (
                                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
                                    {error}
                                </div>
                            )}

                            <form onSubmit={handleSubmitBid} className="space-y-4">
                                <div className="grid md:grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">
                                            Your Bid Amount (₦) *
                                        </label>
                                        <input
                                            type="number"
                                            required
                                            min="1"
                                            placeholder="Enter your price"
                                            className="input-field"
                                            value={bidAmount}
                                            onChange={(e) => setBidAmount(e.target.value)}
                                        />
                                        <p className="text-xs text-gray-500 mt-1">
                                            Suggested: ₦{job.computedPrice?.toLocaleString()}
                                        </p>
                                    </div>

                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">
                                            Estimated Time (minutes) *
                                        </label>
                                        <input
                                            type="number"
                                            required
                                            min="1"
                                            placeholder="e.g., 30"
                                            className="input-field"
                                            value={bidEta}
                                            onChange={(e) => setBidEta(e.target.value)}
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Message to Shipper (Optional)
                                    </label>
                                    <textarea
                                        rows={3}
                                        placeholder="Tell the shipper why you're the best choice..."
                                        className="input-field"
                                        value={bidMessage}
                                        onChange={(e) => setBidMessage(e.target.value)}
                                    />
                                </div>

                                <div className="flex gap-4">
                                    <button
                                        type="submit"
                                        disabled={submitting}
                                        className="btn-primary flex-1"
                                    >
                                        {submitting ? 'Submitting...' : 'Submit Bid'}
                                    </button>
                                    <Link href="/carrier/dashboard" className="btn-secondary">
                                        Cancel
                                    </Link>
                                </div>
                            </form>
                        </div>
                    )}

                    {!canBid && (
                        <div className="card text-center py-8">
                            <p className="text-gray-600">
                                This job is no longer available for bidding.
                            </p>
                            <Link href="/carrier/dashboard" className="btn-primary mt-4 inline-block">
                                View Available Jobs
                            </Link>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
