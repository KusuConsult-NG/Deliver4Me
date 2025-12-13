// lib/middleware.ts
import { NextRequest } from 'next/server';
import { verifyAccessToken } from './auth';
import { errorResponse } from './response';
import { UserRole } from '@prisma/client';

export interface AuthenticatedRequest extends NextRequest {
    user?: {
        userId: string;
        phone: string;
        role: UserRole;
    };
}

/**
 * Middleware to authenticate requests using JWT
 */
export function authenticate(request: NextRequest) {
    const authHeader = request.headers.get('authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { authenticated: false, error: errorResponse('No token provided', 401) };
    }

    const token = authHeader.substring(7);
    const payload = verifyAccessToken(token);

    if (!payload) {
        return { authenticated: false, error: errorResponse('Invalid or expired token', 401) };
    }

    return {
        authenticated: true,
        user: payload,
    };
}

/**
 * Check if user has required role
 */
export function hasRole(userRole: UserRole, allowedRoles: UserRole[]) {
    return allowedRoles.includes(userRole);
}

/**
 * Async authentication helper for API routes
 */
export async function requireAuth(request: NextRequest) {
    const authHeader = request.headers.get('authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { valid: false, error: 'No token provided' };
    }

    const token = authHeader.substring(7);
    const payload = verifyAccessToken(token);

    if (!payload) {
        return { valid: false, error: 'Invalid or expired token' };
    }

    return {
        valid: true,
        userId: payload.userId,
        phone: payload.phone,
        role: payload.role,
    };
}
