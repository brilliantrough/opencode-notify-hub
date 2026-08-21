import type { JSONSchema } from "json-schema-to-ts";

const usernameProperty = {
  type: "string",
  minLength: 1,
  maxLength: 64,
} as const;

const passwordProperty = {
  type: "string",
  minLength: 8,
  maxLength: 128,
} as const;

const emailProperty = { type: "string", format: "email" } as const;

/** DNS domain such as `nju.edu.cn`; matched case-insensitively and stored lowercase. */
const domainProperty = {
  type: "string",
  pattern: "^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$",
  minLength: 4,
  maxLength: 253,
} as const;

export const adminLoginBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["username", "password"],
  properties: {
    username: usernameProperty,
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const adminChangePasswordBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["currentPassword", "newPassword"],
  properties: {
    currentPassword: { type: "string", minLength: 1, maxLength: 128 },
    newPassword: passwordProperty,
  },
} as const satisfies JSONSchema;

export const adminCreateUserBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["email", "password"],
  properties: {
    email: emailProperty,
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const adminResetPasswordBodySchema = {
  type: "object",
  additionalProperties: false,
  required: ["password"],
  properties: {
    password: passwordProperty,
  },
} as const satisfies JSONSchema;

export const adminWhitelistSchema = {
  type: "object",
  additionalProperties: false,
  required: ["domains", "emails"],
  properties: {
    domains: {
      type: "array",
      maxItems: 1000,
      items: domainProperty,
      description: "Address-suffix allowlist entries such as nju.edu.cn.",
    },
    emails: {
      type: "array",
      maxItems: 1000,
      items: emailProperty,
      description: "Exact-address allowlist entries.",
    },
  },
} as const satisfies JSONSchema;

export const adminTokenSchema = {
  type: "object",
  additionalProperties: false,
  required: ["accessToken"],
  properties: {
    accessToken: {
      type: "string",
      minLength: 1,
      description: "Admin JWT; admin sessions live longer than user sessions.",
    },
  },
} as const satisfies JSONSchema;

const adminUserObjectSchema = {
  type: "object",
  additionalProperties: false,
  required: ["id", "email", "verified", "createdAt"],
  properties: {
    id: { type: "string", format: "uuid" },
    email: emailProperty,
    verified: { type: "boolean" },
    createdAt: { type: "string", format: "date-time" },
  },
} as const satisfies JSONSchema;

export const adminUserSchema = adminUserObjectSchema;

export const adminUserListSchema = {
  type: "object",
  additionalProperties: false,
  required: ["total", "users"],
  properties: {
    total: { type: "integer", minimum: 0 },
    users: { type: "array", items: adminUserObjectSchema },
  },
} as const satisfies JSONSchema;
