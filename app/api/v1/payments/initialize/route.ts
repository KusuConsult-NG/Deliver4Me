import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { verifyAccessToken } from '@/lib/auth';
import { successResponse, errorResponse } from '@/lib/response';
import { calculatePlatformFee, calculateCarrierAmount } from '@/lib/pricing';

/**
 * Initialize Paystack Payment
 * POST /api/v1/payments/initialize
 */
export async function POST(request: NextRequest) {
    try {
        // Verify authentication
        const token = request.headers.get('authorization')?.replace('Bearer ', '');
        if (!token) {
            return NextResponse.json(
                errorResponse('No token provided', 401),
                { status: 401 }
            );
        }

        const decoded = verifyAccessToken(token);
        if (!decoded) {
            return NextResponse.json(
                errorResponse('Invalid token', 401),
                { status: 401 }
            );
        }

        const body = await request.json();
        const { jobId } = body;

        if (!jobId) {
            return NextResponse.json(
                errorResponse('Job ID is required', 400),
                { status: 400 }
            );
        }

        // Get job details
        const job = await prisma.job.findUnique({
            where: { id: jobId },
            include: {
                shipper: true,
                carrier: true,
            }
        });

        if (!job) {
            return NextResponse.json(
                errorResponse('Job not found', 404),
                { status: 404 }
            );
        }

        // Verify shipper owns this job
        if (job.shipperId !== decoded.userId) {
            return NextResponse.json(
                errorResponse('Not authorized', 403),
                { status: 403 }
            );
        }

        // Check if job is matched
        if (job.status !== 'MATCHED') {
            return NextResponse.json(
                errorResponse('Job must be matched before payment', 400),
                { status: 400 }
            );
        }

        // Check if payment already exists
        const existingPayment = await prisma.payment.findFirst({
            where: {
                jobId: job.id,
                status: { in: ['COMPLETED', 'PROCESSING'] }
            }
        });

        if (existingPayment) {
            return NextResponse.json(
                errorResponse('Payment already processed for this job', 400),
                { status: 400 }
            );
        }

        const amount = job.finalPrice || job.computedPrice || 0;
        const platformFee = calculatePlatformFee(amount);
        const carrierAmount = calculateCarrierAmount(amount);

        // Create payment record
        const payment = await prisma.payment.create({
            data: {
                jobId: job.id,
                amount,
                platformFee,
                carrierAmount,
                status: 'PENDING',
            }
        });

        // Check if Paystack is configured
        const paystackSecret = process.env.PAYSTACK_SECRET;
        const paystackPublic = process.env.NEXT_PUBLIC_PAYSTACK_PUBLIC;

        if (!paystackSecret || !paystackPublic) {
            // For testing without Paystack credentials

            return NextResponse.json(
                successResponse({
                    payment: {
                        id: payment.id,
                        amount,
                        platformFee,
                        carrierAmount,
                        status: 'PENDING',
                    },
                    paystackConfig: {
                        publicKey: 'TEST_MODE',
                        reference: `test-${payment.id}`,
                        amount: amount * 100, // Paystack expects amount in kobo
                        email: job.shipper.email || `${job.shipper.phone}@deliverme.ng`,
                    },
                    testMode: true,
                    message: 'Paystack not configured. Use test reference to simulate payment.',
                }, 'Payment initialized in test mode')
            );
        }

        // Initialize Paystack transaction
        const reference = `DM-${Date.now()}-${payment.id}`;

        try {
            const paystackResponse = await fetch('https://api.paystack.co/transaction/initialize', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${paystackSecret}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    email: job.shipper.email || `${job.shipper.phone}@deliverme.ng`,
                    amount: amount * 100, // Convert to kobo
                    reference,
                    callback_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/shipper/jobs/${job.id}?payment=success`,
                    metadata: {
                        jobId: job.id,
                        paymentId: payment.id,
                        shipperId: job.shipperId,
                        carrierId: job.carrierId,
                    }
                }),
            });

            const paystackData = await paystackResponse.json();

            if (!paystackData.status) {
                throw new Error(paystackData.message || 'Paystack initialization failed');
            }

            // Update payment with Paystack reference
            await prisma.payment.update({
                where: { id: payment.id },
                data: {
                    paystackRef: reference,
                    status: 'PROCESSING',
                }
            });

            return NextResponse.json(
                successResponse({
                    payment: {
                        id: payment.id,
                        amount,
                        platformFee,
                        carrierAmount,
                        status: 'PROCESSING',
                        reference,
                    },
                    paystack: {
                        authorization_url: paystackData.data.authorization_url,
                        access_code: paystackData.data.access_code,
                        reference: paystackData.data.reference,
                    }
                }, 'Payment initialized successfully')
            );

        } catch (paystackError: any) {
            console.error('Paystack error:', paystackError);

            return NextResponse.json(
                errorResponse(
                    `Payment initialization failed: ${paystackError.message}`,
                    500
                ),
                { status: 500 }
            );
        }

    } catch (error: any) {
        console.error('Payment initialization error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
