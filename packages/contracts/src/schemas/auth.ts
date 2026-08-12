import type { JSONSchema } from "json-schema-to-ts";

const emailProperty = { type: "string", format: "email" } as const;
const passwordProperty = { type: "string", minLength: 8, maxLength: 128 } as const;
// Eight-character high-entropy alphanumeric code delivered over SMTP
// (email verification and password reset share the format).
const oneTimeCodeProperty = {
  type: "string",
  minLength: 8,
  maxLength: 8,
  pattern: "^[A-Za-z0-9]{8}$",
  description: "Eight-character high-entropy alphanumeric code delivered over SMTP.",
} as const;

export const registerBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email", "password"],
  properties: {
    email: emailProperty,
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const loginBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email", "password"],
  properties: {
    email: emailProperty,
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const emailBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email"],
  properties: { email: emailProperty },
} as const satisfies JSONSchema;

export const verifyEmailBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email", "code"],
  properties: { email: emailProperty, code: oneTimeCodeProperty },
} as const satisfies JSONSchema;

export const resetPasswordBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email", "code", "password"],
  properties: {
    email: emailProperty,
    code: oneTimeCodeProperty,
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const refreshBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["refreshToken"],
  properties: { refreshToken: { type: "string", minLength: 1 } },
} as const satisfies JSONSchema;

export const tokenPairSchema = {
  type: "object",
  additionalProperties: false,
  required: ["accessToken", "refreshToken"],
  properties: {
    accessToken: {
      type: "string",
      minLength: 1,
      description: "JWT access token, valid for 15 minutes.",
    },
    refreshToken: {
      type: "string",
      minLength: 1,
      description: "Opaque refresh token, valid for 30 days; rotated on every refresh.",
    },
  },
} as const satisfies JSONSchema;
