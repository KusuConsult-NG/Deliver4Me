# Deliver4Me API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication
All protected endpoints require a Bearer token:
```
Authorization: Bearer {accessToken}
```

---

## Authentication Endpoints

### POST /auth/signup
Create a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "08012345678",
  "password": "password123",
  "role": "SHIPPER" | "CARRIER" | "DRIVER"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "name": "...", "role": "..." },
    "accessToken": "...",
    "refreshToken": "..."
  }
}
```

### POST /auth/login
Login to existing account.

**Request Body:**
```json
{
  "phone": "08012345678",
  "password": "password123"
}
```

---

## Job Endpoints

### POST /jobs
Create a new delivery job.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "pickupAddress": "Victoria Island, Lagos",
  "pickupLat": 6.4281,
  "pickupLng": 3.4219,
  "dropoffAddress": "Lekki, Lagos",
  "dropoffLat": 6.4474,
  "dropoffLng": 3.4710,
  "cargoType": "Documents",
  "cargoWeight": 2.0,
  "cargoDescription": "Important documents",
  "pricingMode": "OPEN_BIDS" | "INSTANT_PRICE"
}
```

### GET /jobs
List all jobs (filtered by user role).

### GET /jobs/{id}
Get job details.

### PUT /jobs/{id}
Update job (only POSTED status).

**Request Body:**
```json
{
  "cargoDescription": "Updated description"
}
```

### DELETE /jobs/{id}
Cancel job.

**Request Body:**
```json
{
  "reason": "Cancellation reason"
}
```

### POST /jobs/{id}/start
Start delivery (carrier/driver only).

### POST /jobs/{id}/complete
Mark job as delivered (carrier/driver only).

---

## Bid Endpoints

### POST /jobs/{id}/bids
Place a bid on a job.

**Request Body:**
```json
{
  "amount": 450,
  "etaMinutes": 30,
  "message": "I can deliver quickly"
}
```

### GET /jobs/{id}/bids
List all bids for a job.

### POST /jobs/{id}/accept
Accept a bid (shipper only).

**Request Body:**
```json
{
  "bidId": "bid-uuid"
}
```

---

## Tracking Endpoints

### POST /tracking
Add a tracking point.

**Request Body:**
```json
{
  "jobId": "job-uuid",
  "latitude": 6.5244,
  "longitude": 3.3792,
  "notes": "At pickup location"
}
```

### GET /jobs/{id}/tracking
Get all tracking points for a job.

---

## Payment Endpoints

### POST /payments/initialize
Initialize Paystack payment.

**Request Body:**
```json
{
  "jobId": "job-uuid"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment": { "id": "...", "amount": 450 },
    "paystack": {
      "authorization_url": "https://checkout.paystack.com/...",
      "reference": "DM-..."
    }
  }
}
```

### GET /payments/verify/{reference}
Verify payment status.

### POST /payments/webhook
Paystack webhook handler (signature verified).

---

## User Endpoints

### GET /users/profile
Get current user profile.

**Response:**
```json
{
  "id": "...",
  "name": "John Doe",
  "phone": "08012345678",
  "email": "john@example.com",
  "role": "SHIPPER",
  "kycStatus": "PENDING",
  "rating": 4.5,
  "totalJobs": 10
}
```

### PUT /users/profile
Update user profile.

**Request Body:**
```json
{
  "name": "New Name",
  "email": "newemail@example.com"
}
```

### PUT /users/password
Change password.

**Request Body:**
```json
{
  "currentPassword": "old123",
  "newPassword": "new123"
}
```

### GET /users/{id}/ratings
Get user ratings and reviews.

---

## Rating Endpoints

### POST /ratings
Submit a rating after job completion.

**Request Body:**
```json
{
  "jobId": "job-uuid",
  "ratedUserId": "user-uuid",
  "score": 5,
  "comment": "Excellent service!"
}
```

---

## Statistics Endpoints

### GET /stats/shipper
Get shipper statistics.

**Response:**
```json
{
  "totalJobs": 10,
  "activeJobs": 2,
  "completedJobs": 8,
  "totalSpent": 5000,
  "pendingPayments": 0,
  "totalBidsReceived": 45,
  "averageBidsPerJob": 4
}
```

### GET /stats/carrier
Get carrier statistics.

**Response:**
```json
{
  "totalBidsPlaced": 20,
  "bidsAccepted": 10,
  "successRate": 50,
  "totalJobs": 10,
  "activeJobs": 1,
  "completedJobs": 9,
  "totalEarnings": 4500,
  "pendingPayouts": 0,
  "averageEarningsPerJob": 450
}
```

}
```

---

## Notification Endpoints

### GET /notifications
Get user notifications.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `unread` - (optional) Set to "true" to get only unread notifications
- `type` - (optional) Filter by notification type
- `limit` - (optional) Limit number of results (default: 50)

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "...",
        "userId": "...",
        "type": "BID_PLACED",
        "title": "New Bid Received",
        "message": "A carrier has placed a bid on your delivery",
        "data": { "jobId": "...", "bidId": "..." },
        "read": false,
        "createdAt": "2024-12-11T10:00:00Z"
      }
    ],
    "unreadCount": 5
  }
}
```

### POST /notifications/{id}/read
Mark a notification as read.

**Headers:** `Authorization: Bearer {token}`

### DELETE /notifications/{id}/read
Mark a notification as unread.

---

## Payout Endpoints

### GET /payouts
Get payout history (carriers/drivers only).

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `status` - (optional) Filter by status (PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED)
- `limit` - (optional) Limit number of results (default: 50)

**Response:**
```json
{
  "success": true,
  "data": {
    "payouts": [
      {
        "id": "...",
        "amount": 10000,
        "platformFee": 200,
        "netAmount": 9800,
        "status": "COMPLETED",
        "bankName": "First Bank",
        "accountNumber": "1234567890",
        "reference": "PAYOUT-...",
        "initiatedAt": "2024-12-10T10:00:00Z",
        "processedAt": "2024-12-11T10:00:00Z"
      }
    ]
  }
}
```

### POST /payouts
Request a payout.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "amount": 10000,
  "bankName": "First Bank",
  "accountNumber": "1234567890",
  "accountName": "John Doe",
  "notes": "Optional notes"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "amount": 10000,
    "platformFee": 200,
    "netAmount": 9800,
    "status": "PENDING",
    "reference": "PAYOUT-..."
  }
}
```

### GET /payouts/balance
Get current available balance for payout (carriers/drivers only).

**Response:**
```json
{
  "success": true,
  "data": {
    "totalEarnings": 50000,
    "totalPaidOut": 30000,
    "totalPending": 5000,
    "availableBalance": 15000,
    "minPayoutAmount": 1000
  }
}
```

---

## Enhanced Job Filtering

The `GET /jobs` endpoint now supports additional query parameters:

- `status` - Filter by job status (POSTED, MATCHED, IN_TRANSIT, DELIVERED, etc.)
- `dateFrom` - Filter jobs created from this date (ISO 8601 format)
- `dateTo` - Filter jobs created until this date (ISO 8601 format)

**Example:**
```
GET /jobs?status=DELIVERED&dateFrom=2024-12-01&dateTo=2024-12-31
```

---

## Error Responses

All endpoints return errors in this format:
```json
{
  "success": false,
  "error": "Error message",
  "statusCode": 400
}
```

### Common Status Codes
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## Job Status Flow

```
POSTED → MATCHED → IN_TRANSIT → DELIVERED
                              ↘ CANCELLED
                              ↘ DISPUTED
```

## Payment Status Flow

```
PENDING → PROCESSING → COMPLETED
                    ↘ FAILED
```

## Bid Status Flow

```
PENDING → ACCEPTED
      ↘ REJECTED
```
