// lib/pricing.ts

/**
 * Base fare for short deliveries (0-3 km)
 * Can be configured via environment variable BASE_FARE
 */
export const BASE_FARE = Number(process.env.BASE_FARE ?? 400);

/**
 * Legacy rate per kilometer - kept for compatibility
 * Can be configured via environment variable RATE_PER_KM
 */
export const RATE_PER_KM = Number(process.env.RATE_PER_KM ?? 50);

/**
 * Platform commission percentage (default 10% - competitive with market)
 * Can be configured via environment variable PLATFORM_FEE_PERCENT
 */
export const PLATFORM_FEE_PERCENT = Number(process.env.PLATFORM_FEE_PERCENT ?? 10);

/**
 * Compute price based on weight and distance using Deliver4Me's pricing:
 * 
 * Base Price (by weight):
 * - 0-2 kg:    ₦700
 * - 2-7 kg:    ₦700 (same as base)
 * - 7+ kg:     ₦1,000
 * 
 * Distance Multipliers:
 * - 0-10 km:   1.2× (+20%)
 * - 10-30 km:  1.5× (+50%)
 * - 30+ km:    NEGOTIABLE (pricing mode must be set to NEGOTIABLE)
 * 
 * Examples:
 * - 2kg × 5km = ₦700 × 1.2 = ₦840
 * - 5kg × 5km = ₦700 × 1.2 = ₦840
 * - 10kg × 5km = ₦1,000 × 1.2 = ₦1,200
 * - 2kg × 15km = ₦700 × 1.5 = ₦1,050
 * - 10kg × 15km = ₦1,000 × 1.5 = ₦1,500
 * - 10kg × 35km = NEGOTIABLE
 * 
 * @param distanceKm - Distance in kilometers
 * @param weightKg - Cargo weight in kilograms
 * @param forceCalculate - Force calculation even for 30+ km (for estimates)
 * @returns Price in Nigerian Naira, or null if negotiable
 */
export function computePrice(
  distanceKm: number,
  weightKg: number = 2,
  forceCalculate: boolean = false
): number | null {
  // For distances 30km+, pricing should be negotiable
  if (distanceKm >= 30 && !forceCalculate) {
    return null; // Indicates NEGOTIABLE pricing
  }

  // Get base price from weight
  const basePrice = getBasePriceByWeight(weightKg);

  // Get distance multiplier
  const distanceMultiplier = getDistanceMultiplier(distanceKm);

  // Calculate final price
  const finalPrice = Math.ceil(basePrice * distanceMultiplier);

  return finalPrice;
}

/**
 * Get base price based on cargo weight
 * 
 * @param weightKg - Weight in kilograms
 * @returns Base price before distance multiplier
 */
export function getBasePriceByWeight(weightKg: number): number {
  if (weightKg < 7) {
    return 700;  // 0-7kg base price
  } else {
    return 1000;  // 7kg+ base price
  }
}

/**
 * Get distance multiplier
 * 
 * @param distanceKm - Distance in kilometers
 * @returns Multiplier to apply to base price
 */
export function getDistanceMultiplier(distanceKm: number): number {
  if (distanceKm <= 10) {
    return 1.2;  // +20% for 0-10km
  } else if (distanceKm <= 30) {
    return 1.5;  // +50% for 10-30km
  } else {
    return 2.0;  // For estimate purposes only (should be negotiable)
  }
}

/**
 * Get weight multiplier based on cargo weight (DEPRECATED - kept for compatibility)
 */
export function getWeightMultiplier(weightKg: number): number {
  // This function is deprecated but kept for backward compatibility
  return 1.0;
}

/**
 * Get pricing tier information for display
 * 
 * @param distanceKm - Distance in kilometers
 * @returns Tier information object
 */
export function getPricingTier(distanceKm: number): {
  tier: number;
  tierName: string;
  basePrice: number;
  perKmRate: number;
  description: string;
} {
  if (distanceKm <= 3) {
    return {
      tier: 1,
      tierName: 'Short Distance',
      basePrice: BASE_FARE,
      perKmRate: 0,
      description: `Flat ₦${BASE_FARE} for deliveries up to 3km`,
    };
  } else if (distanceKm <= 10) {
    return {
      tier: 2,
      tierName: 'Medium Distance',
      basePrice: BASE_FARE,
      perKmRate: 60,
      description: `₦${BASE_FARE} base + ₦60 / km after 3km`,
    };
  } else if (distanceKm <= 20) {
    return {
      tier: 3,
      tierName: 'Long Distance',
      basePrice: 820,
      perKmRate: 50,
      description: '₦820 base (up to 10km) + ₦50/km after 10km',
    };
  } else {
    return {
      tier: 4,
      tierName: 'Extra Long Distance',
      basePrice: 1320,
      perKmRate: 45,
      description: '₦1,320 base (up to 20km) + ₦45/km after 20km',
    };
  }
}

/**
 * Calculate platform commission from a given amount
 * 
 * @param amount - Total amount
 * @returns Platform commission
 */
export function calculatePlatformFee(amount: number): number {
  return Math.round(amount * (PLATFORM_FEE_PERCENT / 100));
}

/**
 * Calculate carrier's amount after platform commission
 * 
 * @param amount - Total amount
 * @returns Carrier's amount after commission
 */
export function calculateCarrierAmount(amount: number): number {
  return amount - calculatePlatformFee(amount);
}

/**
 * Compare Deliver4Me price with competitor prices
 * 
 * @param distanceKm - Distance in kilometers
 * @param weightKg - Cargo weight in kilograms
 * @returns Comparison object including Deliver4Me price, competitor prices, market average, and savings.
 *          Returns null for savings if Deliver4Me price is negotiable.
 */
export function comparePriceWithCompetitors(
  distanceKm: number,
  weightKg: number = 2
): {
  deliverMe: number | null;
  gokada: number;
  kwik: number;
  marketAvg: number;
  savings: number | null;
  savingsPercent: number | null;
} {
  const deliverMePrice = computePrice(distanceKm, weightKg, true);
  const gokadaPrice = Math.ceil(distanceKm * 130);
  const kwikPrice = Math.ceil(distanceKm * 125);
  const marketAvg = Math.ceil((gokadaPrice + kwikPrice) / 2);

  // If price is negotiable, savings can't be calculated
  if (deliverMePrice === null) {
    return {
      deliverMe: null,
      gokada: gokadaPrice,
      kwik: kwikPrice,
      marketAvg,
      savings: null,
      savingsPercent: null,
    };
  }

  const savings = marketAvg - deliverMePrice;
  const savingsPercent = Math.round((savings / marketAvg) * 100);

  return {
    deliverMe: deliverMePrice,
    gokada: gokadaPrice,
    kwik: kwikPrice,
    marketAvg,
    savings: Math.max(0, savings),
    savingsPercent: Math.max(0, savingsPercent),
  };
}
