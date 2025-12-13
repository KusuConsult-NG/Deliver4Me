# Deliver4Me

A Next.js web application that connects shippers and carriers with distance-based pricing.

## Features

- **Competitive Tiered Pricing**: 20-27% cheaper than competitors
  - 0-3 km: ₦400 flat
  - 3-10 km: ₦400 + ₦60/km
  - 10-20 km: ₦820 + ₦50/km  
  - 20+ km: ₦1,320 + ₦45/km
- **Role-based System**: Support for Shippers, Carriers, Drivers, Brokers, and Admins
- **Real-time Tracking**: WebSocket-based location tracking
- **Secure Authentication**: JWT-based auth with role-based access control
- **Mobile-first Design**: Responsive UI with offline support for drivers
- **Payment Integration**: Paystack payment gateway (configurable)

## Tech Stack

- **Frontend**: Next.js 14 (App Router), React, TypeScript, TailwindCSS
- **Backend**: Next.js API Routes, Prisma ORM
- **Database**: PostgreSQL
- **Authentication**: JWT tokens with bcrypt password hashing
- **Maps**: Google Maps API (or Mapbox alternative)
- **Payments**: Paystack

## Getting Started

### Prerequisites

- Node.js 18+ (recommended: 20+)
- PostgreSQL database
- Google Maps API key (optional, falls back to Haversine calculation)
- Paystack account (optional for payments)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Deliver4Me
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
```

Edit `.env` and configure:
```env
DATABASE_URL="postgresql://user:password@localhost:5432/deliverme"
RATE_PER_KM=150
PLATFORM_FEE_PERCENT=7

# Auth
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-super-secret-refresh-key

# Paystack (optional)
PAYSTACK_SECRET=sk_test_your_secret_key
NEXT_PUBLIC_PAYSTACK_PUBLIC=pk_test_your_public_key

# Google Maps (optional)
NEXT_PUBLIC_MAPS_API_KEY=your_google_maps_api_key
```

4. Set up the database:
```bash
npx prisma migrate dev --name init
npx prisma generate
```

5. (Optional) Seed the database:
```bash
npx prisma db seed
```

6. Run the development server:
```bash
npm run dev
```

7. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
/deliverme
  /app
    /api/v1          # API routes
    /auth            # Authentication pages
    /shipper         # Shipper dashboard
    /carrier         # Carrier/Driver dashboard
    /admin           # Admin panel
  /components        # Reusable UI components
  /lib              # Utility functions
    /prisma.ts      # Prisma client
    /auth.ts        # Authentication utilities
    /pricing.ts     # Pricing calculations
    /geo.ts         # Geocoding utilities
    /matching.ts    # Carrier matching algorithm
  /prisma
    /schema.prisma  # Database schema
```

## Key Features

### Pricing Logic

Deliver4Me uses a **competitive tiered pricing model** that's 20-27% cheaper than competitors:

**Tier 1 (0-3 km):** ₦400 flat rate  
**Tier 2 (3-10 km):** ₦400 + (distance - 3) × ₦60/km  
**Tier 3 (10-20 km):** ₦820 + (distance - 10) × ₦50/km  
**Tier 4 (20+ km):** ₦1,320 + (distance - 20) × ₦45/km  

**Examples:**
- 2 km → ₦400 (vs Gokada ₦580) - **31% cheaper**
- 5 km → ₦520 (vs Gokada ₦820) - **37% cheaper**
- 15 km → ₦1,070 (vs Gokada ₦1,700) - **37% cheaper**
- 25 km → ₦1,545 (vs Gokada ₦2,500) - **38% cheaper**

See [PRICING_ANALYSIS.md](PRICING_ANALYSIS.md) for detailed market comparison.

### User Roles

1. **SHIPPER**: Posts delivery jobs
2. **CARRIER**: Fleet owner who accepts jobs
3. **DRIVER**: Delivers items and tracks location
4. **BROKER**: Marketplace facilitator
5. **ADMIN**: Platform administrator

### Job Workflow

1. Shipper creates a job with pickup and dropoff locations
2. System calculates distance and price
3. Carriers/Drivers can bid on the job (or instant match)
4. Shipper accepts a bid
5. Driver picks up and delivers the item
6. Real-time tracking during transit
7. Proof of delivery and payment settlement

## API Endpoints

### Authentication
- `POST /api/v1/auth/signup` - Create new account
- `POST /api/v1/auth/login` - Login

### Jobs
- `POST /api/v1/jobs` - Create job (shipper only)
- `GET /api/v1/jobs` - List jobs
- `GET /api/v1/jobs/:id` - Get job details
- `PATCH /api/v1/jobs/:id` - Update job status

## Configuration

### Environment Variables

- `DATABASE_URL`: PostgreSQL connection string
- `BASE_FARE`: Base delivery price for 0-3km (default: 400)
- `RATE_PER_KM`: Legacy per-kilometer rate (default: 50)
- `PLATFORM_FEE_PERCENT`: Commission percentage (default: 10)
- `JWT_SECRET`: Secret for access tokens
- `JWT_REFRESH_SECRET`: Secret for refresh tokens
- `PAYSTACK_SECRET`: Paystack secret key
- `NEXT_PUBLIC_PAYSTACK_PUBLIC`: Paystack public key
- `NEXT_PUBLIC_MAPS_API_KEY`: Google Maps API key

## Development

```bash
# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linter
npm run lint

# Generate Prisma client
npx prisma generate

# Create database migration
npx prisma migrate dev --name migration_name

# Open Prisma Studio
npx prisma studio
```

## Deployment

### Vercel (Recommended)

1. Push code to GitHub
2. Import project in Vercel
3. Configure environment variables
4. Deploy

### Database

Use a managed PostgreSQL service:
- [Supabase](https://supabase.com)
- [Railway](https://railway.app)
- [Neon](https://neon.tech)
- AWS RDS
- Google Cloud SQL

## License

MIT

## Support

For support, email support@deliverme.ng or join our Slack channel.
