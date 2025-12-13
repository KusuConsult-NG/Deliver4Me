import Link from 'next/link'

export default function Home() {
    return (
        <main className="min-h-screen bg-gradient-to-br from-brand-green-50 to-white">
            <div className="container mx-auto px-4 py-16">
                <div className="max-w-4xl mx-auto text-center">
                    <h1 className="text-5xl md:text-6xl font-bold text-brand-green-500 mb-6">
                        Welcome to Deliver4Me
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-700 mb-8">
                        Connect shippers and carriers with distance-based pricing
                    </p>
                    <p className="text-xl text-gray-600 mb-8">
                        Fast, reliable, and affordable logistics for businesses across Nigeria.
                        Starting from just ₦400 with competitive tiered pricing.
                    </p>

                    <div className="grid md:grid-cols-3 gap-6 mb-12">
                        <div className="card">
                            <div className="text-4xl mb-4">📦</div>
                            <h3 className="text-xl font-semibold text-brand-green-600 mb-2">For Shippers</h3>
                            <p className="text-gray-600">Post jobs and connect with verified carriers instantly</p>
                        </div>
                        <div className="card">
                            <div className="text-4xl mb-4">🚚</div>
                            <h3 className="text-xl font-semibold text-brand-green-600 mb-2">For Carriers</h3>
                            <p className="text-gray-600">Find jobs nearby and grow your delivery business</p>
                        </div>
                        <div className="card">
                            <div className="text-4xl mb-4">📱</div>
                            <h3 className="text-xl font-semibold text-brand-green-600 mb-2">Mobile First</h3>
                            <p className="text-gray-600">Full offline support and real-time tracking</p>
                        </div>
                    </div>

                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <Link href="/auth/signup" className="btn-primary">
                            Get Started
                        </Link>
                        <Link href="/auth/login" className="btn-secondary">
                            Sign In
                        </Link>
                    </div>
                </div>
            </div>
        </main>
    )
}
