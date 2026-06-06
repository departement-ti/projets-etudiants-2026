/**
 * Mock payment service — mimics Stripe's interface with fake synchronous responses.
 *
 * V0: no real money, no API keys, all calls resolve instantly in the same request.
 * V1: swap this file's internals for real Stripe SDK calls.
 *     Controllers, services, and middleware remain untouched.
 */

import { randomUUID } from "crypto";
import type { BillingInterval } from "@prisma/client";

export interface CreateSubscriptionResult {
  subscriptionId: string;
  status: "active";
}

export interface CreatePaymentIntentResult {
  paymentIntentId: string;
  status: "succeeded";
}

export interface CancelSubscriptionResult {
  status: "canceled";
}

export function createSubscription(
  communityId: string,
  userId: string,
  interval: BillingInterval
): CreateSubscriptionResult {
  return {
    subscriptionId: `mock_sub_${randomUUID()}`,
    status: "active",
  };
}

export function createPaymentIntent(
  communityId: string,
  userId: string,
  amount: number
): CreatePaymentIntentResult {
  return {
    paymentIntentId: `mock_pi_${randomUUID()}`,
    status: "succeeded",
  };
}

export function cancelSubscription(subscriptionId: string): CancelSubscriptionResult {
  return { status: "canceled" };
}
