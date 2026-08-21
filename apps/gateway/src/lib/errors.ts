import type { ErrorResponse } from "@notify/contracts";

/**
 * Error codes emitted by the gateway. Response bodies always match the
 * shared `ErrorResponse` contract from `@notify/contracts`
 * (`{ error: { code, message } }`).
 */
export const ErrorCodes = {
  NOT_FOUND: "NOT_FOUND",
  VALIDATION_FAILED: "VALIDATION_FAILED",
  BAD_REQUEST: "BAD_REQUEST",
  UNAUTHORIZED: "UNAUTHORIZED",
  FORBIDDEN: "FORBIDDEN",
  CONFLICT: "CONFLICT",
  UNSUPPORTED_MEDIA_TYPE: "UNSUPPORTED_MEDIA_TYPE",
  RATE_LIMITED: "RATE_LIMITED",
  CLIENT_ERROR: "CLIENT_ERROR",
  INTERNAL: "INTERNAL",
  // Semantic auth-domain codes on top of the HTTP status.
  EMAIL_TAKEN: "EMAIL_TAKEN",
  EMAIL_NOT_ALLOWED: "EMAIL_NOT_ALLOWED",
  INVALID_CODE: "INVALID_CODE",
  SERVICE_UNAVAILABLE: "SERVICE_UNAVAILABLE",
  // Authenticated session flows.
  INVALID_CREDENTIALS: "INVALID_CREDENTIALS",
  EMAIL_UNVERIFIED: "EMAIL_UNVERIFIED",
  REFRESH_REUSED: "REFRESH_REUSED",
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

/**
 * An operational error carrying a genuine HTTP status. 5xx statuses are
 * preserved by the app error handler (so a retryable 503 stays a 503) while
 * the response body stays generic — the message is for logs only and never
 * reaches the client.
 */
export class AppError extends Error {
  readonly statusCode: number;

  constructor(message: string, statusCode: number) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
  }
}

export function errorBody(code: ErrorCode, message: string): ErrorResponse {
  return { error: { code, message } };
}

/** Contract error code for a Fastify/client error with the given 4xx status. */
export function clientErrorCode(statusCode: number): ErrorCode {
  switch (statusCode) {
    case 400:
      return ErrorCodes.BAD_REQUEST;
    case 401:
      return ErrorCodes.UNAUTHORIZED;
    case 403:
      return ErrorCodes.FORBIDDEN;
    case 404:
      return ErrorCodes.NOT_FOUND;
    case 415:
      return ErrorCodes.UNSUPPORTED_MEDIA_TYPE;
    case 429:
      return ErrorCodes.RATE_LIMITED;
    default:
      return ErrorCodes.CLIENT_ERROR;
  }
}
