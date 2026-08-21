CREATE TABLE "admin_users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"username" text NOT NULL,
	"password_hash" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "admin_users_username_unique" UNIQUE("username"),
	CONSTRAINT "admin_users_username_normalized" CHECK ("admin_users"."username" = lower(btrim("admin_users"."username")))
);
--> statement-breakpoint
CREATE TABLE "registration_whitelist" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"kind" text NOT NULL,
	"value" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "registration_whitelist_value_unique" UNIQUE("value"),
	CONSTRAINT "registration_whitelist_kind_check" CHECK ("registration_whitelist"."kind" in ('domain', 'email')),
	CONSTRAINT "registration_whitelist_value_normalized" CHECK ("registration_whitelist"."value" = lower(btrim("registration_whitelist"."value")))
);
