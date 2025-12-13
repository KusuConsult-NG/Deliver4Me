# Paystack Payment Integration - Testing Guide

## Setup

### 1. Get Paystack API Keys

1. Sign up at [Paystack](https://paystack.com)
2. Go to Settings → API Keys & Webhooks
3. Copy your **Test Secret Key** and **Test Public Key**

### 2. Configure Environment Variables

Add to your `.env` file:

```env
# Paystack API Keys (Test Mode)
PAYSTACK_SECRET=sk_test_your_secret_key_here
NEXT_PUBLIC_PAYSTACK_PUBLIC=pk_test_your_public_key_here

# App URL (for webhook callbacks)
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 3. Set Up Webhook URL

For local testing, you need to expose your localhost to the internet:

#### Option A: Using ngrok (Recommended)

```bash
# Install ngrok
brew install ngrok

# Start ngrok tunnel
ngrok http 3000
```

You'll get a URL like: `https://abc123.ngrok.io`

#### Option B: Using localtunnel

```bash
# Install localtunnel
npm install -g localtunnel

# Start tunnel
lt --port 3000
```

### 4. Configure Paystack Webhook

1. Go to Paystack Dashboard → Settings → API Keys & Webhooks
2. Scroll to **Webhooks**
3. Add your webhook URL:
   ```
   https://your-ngrok-url.ngrok.io/api/v1/payments/webhook
   ```
4. Save the webhook URL

---

## Testing the Payment Flow

### Step 1: Initialize Payment

```bash
# Get shipper token
SHIPPER_TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"08012345678","password":"password123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['data']['accessToken'])")

# Create a job and accept a bid first (use job ID from testing)
JOB_ID="your-job-id-here"

# Initialize payment
curl -X POST http://localhost:3000/api/v1/payments/initialize \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SHIPPER_TOKEN" \
  -d "{\"jobId\": \"$JOB_ID\"}" | python3 -m json.tool
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "payment": {
      "id": "payment-uuid",
      "amount": 450,
      "platformFee": 31,
      "carrierAmount": 419,
      "status": "PROCESSING",
      "reference": "DM-1234567890-uuid"
    },
    "paystack": {
      "authorization_url": "https://checkout.paystack.com/...",
      "access_code": "abc123",
      "reference": "DM-1234567890-uuid"
    }
  },
  "message": "Payment initialized successfully"
}
```

### Step 2: Make Test Payment

1. Open the `authorization_url` in your browser
2. Use Paystack test cards:
   - **Success**: `4084084084084081` (any CVV, future expiry)
   - **Failure**: `4084080000000408` (any CVV, future expiry)
3. Complete the payment

### Step 3: Webhook Verification

Monitor your server logs to see the webhook event:

```bash
# In your terminal where npm run dev is running, you'll see:
Paystack webhook event: charge.success
Payment successful: { reference: 'DM-1234567890-uuid', jobId: '...', amount: 450 }
```

### Step 4: Verify Payment Status

```bash
# Verify the payment
REFERENCE="DM-1234567890-uuid"

curl -X GET "http://localhost:3000/api/v1/payments/verify/$REFERENCE" \
  -H "Authorization: Bearer $SHIPPER_TOKEN" | python3 -m json.tool
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "payment": {
      "id": "payment-uuid",
      "status": "COMPLETED",
      "amount": 450,
      "paidAt": "2025-12-09T13:45:00.000Z"
    },
    "job": {
      "id": "job-uuid",
      "status": "IN_TRANSIT"
    }
  },
  "message": "Payment verified successfully"
}
```

---

## Testing Webhook Manually

You can simulate webhook events using curl:

```bash
# Get your Paystack secret key
PAYSTACK_SECRET="your-secret-key"

# Create test payload
PAYLOAD='{
  "event": "charge.success",
  "data": {
    "reference": "DM-1234567890-uuid",
    "amount": 45000,
    "status": "success"
  }
}' # Generate signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha512 -hmac "$PAYSTACK_SECRET" | awk '{print $2}')

# Send webhook request
curl -X POST http://localhost:3000/api/v1/payments/webhook \
  -H "Content-Type: application/json" \
  -H "x-paystack-signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

---

## Test Cards

| Card Number | Description | Expected Result |
|-------------|-------------|-----------------|
| 4084084084084081 | Successful transaction | Payment succeeds |
| 4084080000000408 | Insufficient funds | Payment fails |
| 5060666666666666666 | Timeout | Transaction times out |

**Test Details:**
- CVV: Any 3 digits
- Expiry: Any future date
- PIN: 1234 (for cards requiring PIN)
- OTP: 123456 (for cards requiring OTP)

---

## Troubleshooting

### Webhook Not Receiving Events

1. **Check ngrok is running**: Visit `http://127.0.0.1:4040` to see requests
2. **Verify webhook URL**: Ensure it matches in Paystack dashboard
3. **Check signature**: Make sure `PAYSTACK_SECRET` is correct

### Payment Initialization Fails

1. **Check API keys**: Verify `PAYSTACK_SECRET` is set correctly
2. **Check job status**: Job must be in `MATCHED` status
3. **Check network**: Ensure you can reach Paystack API

### Signature Verification Fails

1. **Check secret key**: Must match the one in Paystack dashboard
2. **Check payload**: Body must not be modified before verification
3. **Check headers**: `x-paystack-signature` must be present

---

## Database Verification

Check payment records in Prisma Studio:

```bash
npx prisma studio
```

Navigate to the `Payment` model and verify:
- Status changes: `PENDING` → `PROCESSING` → `COMPLETED`
- `paystackRef` is set
- `paidAt` timestamp is recorded
- Job status updated to `IN_TRANSIT`

---

## Complete Test Flow Example

```bash
# 1. Login as shipper
SHIPPER_TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"08012345678","password":"password123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['data']['accessToken'])")

# 2. Get a matched job ID (from previous testing)
JOB_ID="d6df4e17-21c6-4afc-94a2-3ec563ae632c"

# 3. Initialize payment
PAYMENT_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/payments/initialize \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SHIPPER_TOKEN" \
  -d "{\"jobId\": \"$JOB_ID\"}")

echo "$PAYMENT_RESPONSE" | python3 -m json.tool

# 4. Extract authorization URL
AUTH_URL=$(echo "$PAYMENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['paystack']['authorization_url'])")
REFERENCE=$(echo "$PAYMENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['payment']['reference'])")

echo "Open this URL to complete payment: $AUTH_URL"
echo "Reference: $REFERENCE"

# 5. After completing payment on Paystack, verify it
sleep 5  # Wait for webhook to process

curl -X GET "http://localhost:3000/api/v1/payments/verify/$REFERENCE" \
  -H "Authorization: Bearer $SHIPPER_TOKEN" | python3 -m json.tool
```

---

## Next Steps

After testing the payment integration:

1. ✅ Verify webhook signature validation works
2. ✅ Test successful payment flow
3. ✅ Test failed payment handling
4. ✅ Verify job status updates correctly
5. ✅ Check payment records in database
6. 🔄 Add payment UI to shipper dashboard
7. 🔄 Add notifications for payment events
8. 🔄 Implement payment refunds (if needed)

---

## Production Deployment

When ready for production:

1. Replace test keys with live keys in environment variables
2. Update webhook URL to production domain
3. Test on staging environment first
4. Monitor payment logs closely
5. Set up error alerting (e.g., Sentry)
