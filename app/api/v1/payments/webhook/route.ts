import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { successResponse, errorResponse } from '@/lib/response';
import crypto from 'crypto';

/**
 * Paystack Webhook Handler
 * 
 * This endpoint receives webhook events from Paystack to verify payments
 * It handles the following events:
 * - charge.success: Payment completed successfully
 * - charge.failed: Payment failed
 */
export async function POST(request: NextRequest) {
    try {
        const secret = process.env.PAYSTACK_SECRET;

        if (!secret) {
            console.error('PAYSTACK_SECRET not configured');
            return NextResponse.json(
                errorResponse('Payment service not configured', 500),
                { status: 500 }
            );
        }

        // Get the signature from headers
        const signature = request.headers.get('x-paystack-signature');

        if (!signature) {
            return NextResponse.json(
                errorResponse('No signature provided', 400),
                { status: 400 }
            );
        }

        // Get raw body
        const body = await request.text();

        // Verify signature
        const hash = crypto
            .createHmac('sha512', secret)
            .update(body)
            .digest('hex');

        if (hash !== signature) {
            console.error('Invalid webhook signature');
            return NextResponse.json(
                errorResponse('Invalid signature', 401),
                { status: 401 }
            );
        }

        // Parse the verified body
        const event = JSON.parse(body);

        // Handle different event types
        switch (event.event) {
            case 'charge.success':
                await handlePaymentSuccess(event.data);
                break;

            case 'charge.failed':
                await handlePaymentFailure(event.data);
                break;

            default:
                // Unhandled event type - no action needed
                break;
        }

        // Always return 200 to acknowledge receipt
        return NextResponse.json({ status: 'success' });

    } catch (error: any) {
        console.error('Webhook error:', error);
        return NextResponse.json(
            errorResponse('Webhook processing failed', 500),
            { status: 500 }
        );
    }
}

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(data: any) {
    try {
        const reference = data.reference;

        // Find payment record
        const payment = await prisma.payment.findUnique({
            where: { paystackRef: reference },
            include: {
                job: {
                    include: {
                        shipper: true,
                        carrier: true,
                    }
                }
            }
        });

        if (!payment) {
            console.error('Payment not found:', reference);
            return;
        }

        // Check if already processed
        if (payment.status === 'COMPLETED') {
            return;
        }

        // Update payment status
        await prisma.payment.update({
            where: { id: payment.id },
            data: {
                status: 'COMPLETED',
                paystackStatus: 'success',
                paidAt: new Date(),
            }
        });

        // Update job status to IN_TRANSIT (ready for delivery)
        await prisma.job.update({
            where: { id: payment.jobId },
            data: {
                status: 'IN_TRANSIT',
                startedAt: new Date(),
            }
        });

        // TODO: Send notification to shipper and carrier

    } catch (error) {
        console.error('Error handling payment success:', error);
        throw error;
    }
}

/**
 * Handle failed payment
 */
async function handlePaymentFailure(data: any) {
    try {
        const reference = data.reference;

        // Find payment record
        const payment = await prisma.payment.findUnique({
            where: { paystackRef: reference }
        });

        if (!payment) {
            console.error('Payment not found:', reference);
            return;
        }

        // Update payment status
        await prisma.payment.update({
            where: { id: payment.id },
            data: {
                status: 'FAILED',
                paystackStatus: 'failed',
            }
        });

        // TODO: Send notification to shipper about failed payment

    } catch (error) {
        console.error('Error handling payment failure:', error);
        throw error;
    }
}
