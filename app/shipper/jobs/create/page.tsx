'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function CreateJobPage() {
    const router = useRouter();
    const [formData, setFormData] = useState({
        pickupAddress: '',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: '',
        dropoffLat: 0,
        dropoffLng: 0,
        cargoType: '',
        cargoWeight: '',
        cargoDescription: '',
        bookingMode: 'AUTO_ACCEPT' as 'AUTO_ACCEPT' | 'BIDDING',
        pricingMode: 'INSTANT_PRICE' as 'INSTANT_PRICE' | 'OPEN_BIDS' | 'NEGOTIABLE',
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [estimatedPrice, setEstimatedPrice] = useState<number | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const token = localStorage.getItem('accessToken');
            if (!token) {
                router.push('/auth/login');
                return;
            }

            const response = await fetch('/api/v1/jobs', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    ...formData,
                    cargoWeight: formData.cargoWeight ? parseFloat(formData.cargoWeight) : undefined,
                }),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Failed to create job');
            }

            router.push('/shipper/dashboard');
        } catch (err: any) {
            setError(err.message || 'Something went wrong');
        } finally {
            setLoading(false);
        }
    };

    // Simple geocoding simulation (in production, use Google Maps API)
    const handleAddressLookup = async (type: 'pickup' | 'dropoff') => {
        // For demo purposes, generate random coordinates around Lagos, Nigeria
        const baseLat = 6.5244;
        const baseLng = 3.3792;
        const randomLat = baseLat + (Math.random() - 0.5) * 0.2;
        const randomLng = baseLng + (Math.random() - 0.5) * 0.2;

        if (type === 'pickup') {
            setFormData({
                ...formData,
                pickupLat: randomLat,
                pickupLng: randomLng,
            });
        } else {
            setFormData({
                ...formData,
                dropoffLat: randomLat,
                dropoffLng: randomLng,
            });
        }
    };

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
                <div className="max-w-3xl mx-auto">
                    <h2 className="text-2xl font-bold text-gray-800 mb-6">Create New Delivery Job</h2>

                    {error && (
                        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="card space-y-6">
                        {/* Step 1: Pickup & Dropoff */}
                        <div>
                            <h3 className="text-lg font-semibold text-gray-800 mb-4">📍 Pickup & Dropoff Locations</h3>

                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Pickup Address *
                                    </label>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            required
                                            placeholder="Enter pickup address"
                                            className="input-field flex-1"
                                            value={formData.pickupAddress}
                                            onChange={(e) => setFormData({ ...formData, pickupAddress: e.target.value })}
                                        />
                                        <button
                                            type="button"
                                            className="btn-secondary whitespace-nowrap"
                                            onClick={() => handleAddressLookup('pickup')}
                                        >
                                            Geocode
                                        </button>
                                    </div>
                                    {formData.pickupLat !== 0 && (
                                        <p className="text-xs text-green-600 mt-1">
                                            ✓ Coordinates: {formData.pickupLat.toFixed(4)}, {formData.pickupLng.toFixed(4)}
                                        </p>
                                    )}
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Dropoff Address *
                                    </label>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            required
                                            placeholder="Enter dropoff address"
                                            className="input-field flex-1"
                                            value={formData.dropoffAddress}
                                            onChange={(e) => setFormData({ ...formData, dropoffAddress: e.target.value })}
                                        />
                                        <button
                                            type="button"
                                            className="btn-secondary whitespace-nowrap"
                                            onClick={() => handleAddressLookup('dropoff')}
                                        >
                                            Geocode
                                        </button>
                                    </div>
                                    {formData.dropoffLat !== 0 && (
                                        <p className="text-xs text-green-600 mt-1">
                                            ✓ Coordinates: {formData.dropoffLat.toFixed(4)}, {formData.dropoffLng.toFixed(4)}
                                        </p>
                                    )}
                                </div>
                            </div>
                        </div>

                        {/* Step 2: Cargo Details */}
                        <div className="border-t pt-6">
                            <h3 className="text-lg font-semibold text-gray-800 mb-4">📦 Cargo Details</h3>

                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Cargo Type *
                                    </label>
                                    <select
                                        className="input-field"
                                        value={formData.cargoType}
                                        onChange={(e) => setFormData({ ...formData, cargoType: e.target.value })}
                                        required
                                    >
                                        <option value="">Select cargo type</option>
                                        <option value="Documents">Documents</option>
                                        <option value="Parcels">Parcels</option>
                                        <option value="Food">Food</option>
                                        <option value="Electronics">Electronics</option>
                                        <option value="Furniture">Furniture</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>

                                <div className="grid md:grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-1">
                                            Weight (kg) - Optional
                                        </label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            placeholder="e.g., 5.5"
                                            className="input-field"
                                            value={formData.cargoWeight}
                                            onChange={(e) => setFormData({ ...formData, cargoWeight: e.target.value })}
                                        />
                                    </div>

                                </div>
                            </div>
                        </div>

                        {/* Step 3: Booking Mode */}
                        <div className="border-t pt-6">
                            <h3 className="text-lg font-semibold text-gray-800 mb-4">🚗 Booking Mode</h3>

                            <div className="space-y-3">
                                <label className="flex items-start gap-3 p-4 border-2 rounded-xl cursor-pointer hover:border-brand-green-500 transition-colors" style={{ borderColor: formData.bookingMode === 'AUTO_ACCEPT' ? '#10b981' : '#e5e7eb' }}>
                                    <input
                                        type="radio"
                                        name="bookingMode"
                                        value="AUTO_ACCEPT"
                                        checked={formData.bookingMode === 'AUTO_ACCEPT'}
                                        onChange={(e) => setFormData({ ...formData, bookingMode: 'AUTO_ACCEPT' })}
                                        className="mt-1"
                                    />
                                    <div className="flex-1">
                                        <div className="font-semibold text-gray-800">⚡ Instant Accept (Recommended)</div>
                                        <p className="text-sm text-gray-600 mt-1">
                                            Drivers can instantly accept your job. Get matched in seconds! First driver to accept gets the job. <span className="font-medium text-brand-green-600">Expires in 10 minutes</span> if no driver accepts.
                                        </p>
                                    </div>
                                </label>

                                <label className="flex items-start gap-3 p-4 border-2 rounded-xl cursor-pointer hover:border-brand-green-500 transition-colors" style={{ borderColor: formData.bookingMode === 'BIDDING' ? '#10b981' : '#e5e7eb' }}>
                                    <input
                                        type="radio"
                                        name="bookingMode"
                                        value="BIDDING"
                                        checked={formData.bookingMode === 'BIDDING'}
                                        onChange={(e) => setFormData({ ...formData, bookingMode: 'BIDDING' })}
                                        className="mt-1"
                                    />
                                    <div className="flex-1">
                                        <div className="font-semibold text-gray-800">💰 Collect Bids</div>
                                        <p className="text-sm text-gray-600 mt-1">
                                            Multiple drivers submit bids, you choose the best one. Takes longer but gives you more control over price and driver selection.
                                        </p>
                                    </div>
                                </label>
                            </div>
                        </div>

                        {/* Submit Button */}
                        <div className="flex gap-4 border-t pt-6">
                            <button
                                type="submit"
                                disabled={loading || formData.pickupLat === 0 || formData.dropoffLat === 0}
                                className="btn-primary flex-1"
                            >
                                {loading ? 'Creating Job...' : 'Create Job'}
                            </button>
                            <Link href="/shipper/dashboard" className="btn-secondary">
                                Cancel
                            </Link>
                        </div>

                        <p className="text-xs text-gray-500 text-center">
                            * Note: Click &quot;Geocode&quot; buttons to convert addresses to coordinates (required for pricing)
                        </p>
                    </form>
                </div>
            </div>
        </div>
    );
}
