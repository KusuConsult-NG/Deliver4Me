// lib/response.ts

/**
 * Standard API response utilities
 */

export function successResponse<T = any>(data: T, message?: string) {
    return {
        success: true,
        data,
        message: message || 'Success',
    };
}

export function errorResponse(message: string, statusCode: number = 400, errors?: any) {
    return {
        success: false,
        error: message,
        statusCode,
        errors,
    };
}

export function paginatedResponse<T = any>(
    data: T[],
    page: number,
    limit: number,
    total: number
) {
    return {
        success: true,
        data,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
            hasMore: page * limit < total,
        },
    };
}
