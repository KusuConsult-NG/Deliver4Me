# Deliver4Me - Setup Guide

## Quick Start

This guide will help you get Deliver4Me running locally in just a few minutes.

### 1. Prerequisites

- Node.js 18+ installed
- PostgreSQL database (local or cloud)
- Git

### 2. Clone and Install

```bash
# Navigate to the project directory
cd /Users/mac/Deliver4Me

# Dependencies are already installed
# If you need to reinstall:
# npm install
```

### 3. Set Up Database

#### Option A: Local PostgreSQL

```bash
# Create database
createdb deliverme

# Update .env
DATABASE_URL="postgresql://localhost:5432/deliverme"
```

#### Option B: Cloud Database (Recommended)

Use a free tier from:
- **Supabase**: https://supabase.com (Easiest - includes Postgres + free tier)
- **Neon**: https://neon.tech (Serverless Postgres)
- **Railway**: https://railway.app

After creating a database, copy the connection string to `.env`:

```env
DATABASE_URL="postgresql://user:password@host:5432/deliverme"
```

### 4. Configure Environment Variables

Create a `.env` file:

```bash
cp .env.example .env
```

Minimal configuration for local development:

```env
# Database (REQUIRED)
DATABASE_URL="postgresql://localhost:5432/deliverme"

# Auth secrets (REQUIRED - can use any random string for local dev)
JWT_SECRET="my-super-secret-jwt-key-for-dev"
JWT_REFRESH_SECRET="my-super-secret-refresh-key-for-dev"

# Pricing (optional - has defaults)
RATE_PER_KM=150
PLATFORM_FEE_PERCENT=7

# Optional features (can skip for initial testing)
NEXT_PUBLIC_MAPS_API_KEY=          # For real geocoding
PAYSTACK_SECRET=                    # For payments
NEXT_PUBLIC_PAYSTACK_PUBLIC=        # For payments
```

### 5. Run Migrations

```bash
# Generate Prisma client
npx prisma generate

# Run migrations to create database tables
npx prisma migrate dev --name init

# (Optional) Open Prisma Studio to view your database
npx prisma studio
```

### 6. Start the App

```bash
npm run dev
```

Visit http://localhost:3000

## Testing the App

### 1. Create a Shipper Account

1. Go to http://localhost:3000
2. Click "Get Started"
3. Fill in signup form:
   - Name: Test Shipper
   - Phone: 08012345678
   - Role: **Shipper**
   - Password: password123
4. Click "Sign Up"

### 2. Create a Job

1. You'll be redirected to shipper dashboard
2. Click "Create New Job"
3. Fill in details:
   - Pickup Address: "123 Lagos Street, Lagos"
   - Click "Geocode" to generate coordinates
   - Dropoff Address: "456 Ikeja Avenue, Lagos"
   - Click "Geocode"
   - Cargo Type: Select any
4. Click "Create Job"

### 3. Create a Carrier Account

1. Open an incognito window (or logout)
2. Go to signup page
3. Create account with Role: **Carrier**
4. View available jobs on carrier dashboard
5. Click a job and place a bid

### 4. Accept a Bid (as Shipper)

1. Return to shipper account
2. View your job
3. See the carrier's bid
4. Accept the bid

## Troubleshooting

### "Failed to connect to database"

- Check DATABASE_URL is correct
- Ensure PostgreSQL is running
- Test connection: `psql $DATABASE_URL`

### "Prisma Client not generated"

```bash
npx prisma generate
```

### "Migration failed"

```bash
# Reset database (⚠️ deletes all data)
npx prisma migrate reset

# Then run migration again
npx prisma migrate dev
```

### Port 3000 already in use

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use a different port
npm run dev -- -p 3001
```

## Next Steps

After basic testing:

1. **Get Google Maps API Key** (for real geocoding):
   - Visit https://console.cloud.google.com
   - Enable Maps JavaScript API and Directions API
   - Create API key
   - Add to `.env` as `NEXT_PUBLIC_MAPS_API_KEY`

2. **Set Up Paystack** (for payments):
   - Sign up at https://paystack.com
   - Get test keys from dashboard
   - Add to `.env`

3. **Deploy to Vercel**:
   ```bash
   # Push to GitHub
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin <your-repo>
   git push -u origin main
   
   # Deploy on Vercel
   # Visit vercel.com and import your repo
   ```

## Available Routes

- `/` - Landing page
- `/auth/signup` - Create account
- `/auth/login` - Sign in
- `/shipper/dashboard` - Shipper dashboard
- `/shipper/jobs/create` - Create job
- `/carrier/dashboard` - Carrier dashboard

## API Endpoints

All API routes are under `/api/v1/`:

- `POST /api/v1/auth/signup` - Register
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/jobs` - List jobs
- `POST /api/v1/jobs` - Create job
- `POST /api/v1/jobs/:id/bids` - Place bid
- `POST /api/v1/jobs/:id/accept` - Accept bid

## Database Schema

View with Prisma Studio:

```bash
npx prisma studio
```

Opens at http://localhost:5555

## Need Help?

Check the main README.md for detailed documentation.
