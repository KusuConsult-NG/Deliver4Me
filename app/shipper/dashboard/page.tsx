'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

interface Job {
    id: string;
    pickupAddress: string;
    dropoffAddress: string;
    distanceKm: number;
    computedPrice: number;
    status: string;
    cargoType: string;
    createdAt: string;
    _count: {
        bids: number;
    };
}

interface Stats {
    totalJobs: number;
    activeJobs: number;
    completedJobs: number;
    totalSpent: number;
    pendingPayments: number;
    totalBidsReceived: number;
    averageBidsPerJob: number;
}

export default function ShipperDashboard() {
    const router = useRouter();
    const [jobs, setJobs] = useState<Job[]>([]);
    const [stats, setStats] = useState<Stats | null>(null);
    const [loading, setLoading] = useState(true);
    const [statsLoading, setStatsLoading] = useState(true);

    useEffect(() => {
        // Check authentication
        const token = localStorage.getItem('accessToken');
        if (!token) {
            router.push('/auth/login');
            return;
        }

        fetchJobs();
        fetchStats();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const fetchStats = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch('/api/v1/stats/shipper', {
                headers: { Authorization: `Bearer ${token}` },
            });

            if (response.ok) {
                const data = await response.json();
                setStats(data.data.summary);
            }
        } catch (error) {
            console.error('Error fetching stats:', error);
        } finally {
            setStatsLoading(false);
        }
    };

    const fetchJobs = async () => {
        try {
            const token = localStorage.getItem('accessToken');
            const response = await fetch('/api/v1/jobs', {
                headers: {
                    Authorization: `Bearer ${token}`,
                },
            });

            if (!response.ok) throw new Error('Failed to fetch jobs');

            const data = await response.json();
            setJobs(data.data);
        } catch (error) {
            console.error('Error fetching jobs:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        router.push('/');
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

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white shadow-sm border-b border-gray-200">
                <div className="container mx-auto px-4 py-4 flex justify-between items-center">
                    <h1 className="text-2xl font-bold text-brand-green-500">Deliver4Me</h1>
                    <div className="flex gap-4 items-center">
                        <span className="text-gray-700">Shipper Dashboard</span>
                        <button onClick={handleLogout} className="btn-secondary text-sm py-2">
                            Logout
                        </button>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <div className="container mx-auto px-4 py-8">
                {/* Statistics Cards */}
                {statsLoading ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                        {[...Array(4)].map((_, i) => (
                            <div key={i} className="card animate-pulse">
                                <div className="h-4 bg-gray-200 rounded w-1/2 mb-2"></div>
                                <div className="h-8 bg-gray-200 rounded w-3/4"></div>
                            </div>
                        ))}
                    </div>
                ) : stats && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                        <div className="card bg-gradient-to-br from-blue-50 to-white">
                            <p className="text-sm text-gray-600 mb-1">Total Jobs</p>
                            <p className="text-3xl font-bold text-brand-green-600">{stats.totalJobs}</p>
                            <p className="text-xs text-gray-500 mt-1">{stats.completedJobs} completed</p>
                        </div>

                        <div className="card bg-gradient-to-br from-green-50 to-white">
                            <p className="text-sm text-gray-600 mb-1">Active Shipments</p>
                            <p className="text-3xl font-bold text-blue-600">{stats.activeJobs}</p>
                            <p className="text-xs text-gray-500 mt-1">In progress</p>
                        </div>

                        <div className="card bg-gradient-to-br from-purple-50 to-white">
                            <p className="text-sm text-gray-600 mb-1">Total Bids Received</p>
                            <p className="text-3xl font-bold text-purple-600">{stats.totalBidsReceived}</p>
                            <p className="text-xs text-gray-500 mt-1">Avg {stats.averageBidsPerJob} per job</p>
                        </div>

                        <div className="card bg-gradient-to-br from-emerald-50 to-white">
                            <p className="text-sm text-gray-600 mb-1">Total Spent</p>
                            <p className="text-3xl font-bold text-emerald-600">₦{stats.totalSpent.toLocaleString()}</p>
                            {stats.pendingPayments > 0 && (
                                <p className="text-xs text-orange-600 mt-1">₦{stats.pendingPayments.toLocaleString()} pending</p>
                            )}
                        </div>
                    </div>
                )}

                <div className="flex justify-between items-center mb-6">
                    <h2 className="text-2xl font-bold text-gray-800">My Delivery Jobs</h2>
                    <Link href="/shipper/jobs/create" className="btn-primary">
                        + Create New Job
                    </Link>
                </div>

                {loading ? (
                    <div className="text-center py-12">
                        <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-brand-green-500 border-t-transparent"></div>
                        <p className="mt-4 text-gray-600">Loading jobs...</p>
                    </div>
                ) : jobs.length === 0 ? (
                    <div className="card text-center py-12 bg-gradient-to-br from-brand-green-50 to-white">
                        <div className="text-6xl mb-4">📦</div>
                        <h3 className="text-xl font-semibold text-gray-800 mb-2">No jobs yet</h3>
                        <p className="text-gray-600 mb-6">Create your first delivery job to get started</p>
                        <Link href="/shipper/jobs/create" className="btn-primary inline-block">
                            Create Job
                        </Link>
                    </div>
                ) : (
                    <div className="grid gap-4">
                        {jobs.map((job) => (
                            <Link href={`/shipper/jobs/${job.id}`} key={job.id}>
                                <div className="card hover:shadow-xl transition-shadow cursor-pointer">
                                    <div className="flex justify-between items-start mb-4">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-2">
                                                <span className={`status-chip ${getStatusColor(job.status)}`}>
                                                    {job.status}
                                                </span>
                                                {job._count.bids > 0 && (
                                                    <span className="text-sm text-gray-600">
                                                        {job._count.bids} bid{job._count.bids !== 1 ? 's' : ''}
                                                    </span>
                                                )}
                                            </div>
                                            <h3 className="font-semibold text-gray-800 mb-1">{job.cargoType}</h3>
                                            <p className="text-sm text-gray-600 mb-2">
                                                <span className="font-medium">From:</span> {job.pickupAddress}
                                            </p>
                                            <p className="text-sm text-gray-600">
                                                <span className="font-medium">To:</span> {job.dropoffAddress}
                                            </p>
                                        </div>
                                        <div className="text-right">
                                            <div className="text-2xl font-bold text-brand-green-600">
                                                ₦{job.computedPrice?.toLocaleString()}
                                            </div>
                                            <p className="text-sm text-gray-500">{job.distanceKm?.toFixed(1)} km</p>
                                        </div>
                                    </div>
                                    <div className="text-sm text-gray-500 border-t pt-2">
                                        Posted {new Date(job.createdAt).toLocaleDateString()}
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
