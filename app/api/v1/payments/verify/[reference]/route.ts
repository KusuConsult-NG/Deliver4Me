import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { verifyAccessToken } from '@/lib/auth';
import { successResponse, errorResponse } from '@/lib/response';

/**
 * Verify Paystack Payment
 * GET /api/v1/payments/verify/[reference]
 */
export async function GET(
    request: NextRequest,
    { params }: { params: { reference: string } }
) {
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

        const { reference } = params;

        // Find payment by reference
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
            return NextResponse.json(
                errorResponse('Payment not found', 404),
                { status: 404 }
            );
        }

        // Check if already verified
        if (payment.status === 'COMPLETED') {
            return NextResponse.json(
                successResponse({
                    payment: {
                        id: payment.id,
                        status: payment.status,
                        amount: payment.amount,
                        paidAt: payment.paidAt,
                    },
                    job: {
                        id: payment.job.id,
                        status: payment.job.status,
                    }
                }, 'Payment already verified')
            );
        }

        // Verify with Paystack
        const paystackSecret = process.env.PAYSTACK_SECRET;

        if (!paystackSecret) {
            return NextResponse.json(
                errorResponse('Payment service not configured', 500),
                { status: 500 }
            );
        }

        const paystackResponse = await fetch(
            `https://api.paystack.co/transaction/verify/${reference}`,
            {
                headers: {
                    'Authorization': `Bearer ${paystackSecret}`,
                }
            }
        );

        const paystackData = await paystackResponse.json();

        if (!paystackData.status) {
            return NextResponse.json(
                errorResponse('Payment verification failed', 400),
                { status: 400 }
            );
        }

        const transactionData = paystackData.data;

        // Check if payment was successful
        if (transactionData.status === 'success') {
            // Update payment
            await prisma.payment.update({
                where: { id: payment.id },
                data: {
                    status: 'COMPLETED',
                    paystackStatus: 'success',
                    paidAt: new Date(),
                }
            });

            // Update job status
            await prisma.job.update({
                where: { id: payment.jobId },
                data: {
                    status: 'IN_TRANSIT',
                    startedAt: new Date(),
                }
            });

            return NextResponse.json(
                successResponse({
                    payment: {
                        id: payment.id,
                        status: 'COMPLETED',
                        amount: payment.amount,
                        paidAt: new Date(),
                    },
                    job: {
                        id: payment.job.id,
                        status: 'IN_TRANSIT',
                    }
                }, 'Payment verified successfully')
            );
        } else {
            // Payment failed
            await prisma.payment.update({
                where: { id: payment.id },
                data: {
                    status: 'FAILED',
                    paystackStatus: transactionData.status,
                }
            });

            return NextResponse.json(
                errorResponse('Payment was not successful', 400),
                { status: 400 }
            );
        }

    } catch (error: any) {
        console.error('Payment verification error:', error);
        return NextResponse.json(
            errorResponse('Internal server error', 500),
            { status: 500 }
        );
    }
}
