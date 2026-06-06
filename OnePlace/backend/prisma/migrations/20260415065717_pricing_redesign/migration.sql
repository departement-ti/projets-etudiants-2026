/*
  Warnings:

  - The values [active,cancelled,expired,banned] on the enum `MembershipStatus` will be removed. If these variants are still used in the database, this will fail.
  - The values [pending,success,failed] on the enum `PaymentStatus` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `price` on the `Community` table. All the data in the column will be lost.
  - Added the required column `platformPlan` to the `Community` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "PlatformPlan" AS ENUM ('BASIC', 'PRO');

-- CreateEnum
CREATE TYPE "PricingModel" AS ENUM ('FREE', 'SUBSCRIPTION', 'FREEMIUM', 'ONE_TIME');

-- CreateEnum
CREATE TYPE "BillingInterval" AS ENUM ('MONTHLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "MembershipTier" AS ENUM ('FREE', 'PAID');

-- AlterEnum
BEGIN;
CREATE TYPE "MembershipStatus_new" AS ENUM ('ACTIVE', 'CANCELLED', 'EXPIRED', 'BANNED');
ALTER TABLE "public"."Membership" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Membership" ALTER COLUMN "status" TYPE "MembershipStatus_new" USING ("status"::text::"MembershipStatus_new");
ALTER TYPE "MembershipStatus" RENAME TO "MembershipStatus_old";
ALTER TYPE "MembershipStatus_new" RENAME TO "MembershipStatus";
DROP TYPE "public"."MembershipStatus_old";
ALTER TABLE "Membership" ALTER COLUMN "status" SET DEFAULT 'ACTIVE';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "PaymentStatus_new" AS ENUM ('PENDING', 'SUCCESS', 'FAILED');
ALTER TABLE "public"."Subscription" ALTER COLUMN "paymentStatus" DROP DEFAULT;
ALTER TABLE "Subscription" ALTER COLUMN "paymentStatus" TYPE "PaymentStatus_new" USING ("paymentStatus"::text::"PaymentStatus_new");
ALTER TYPE "PaymentStatus" RENAME TO "PaymentStatus_old";
ALTER TYPE "PaymentStatus_new" RENAME TO "PaymentStatus";
DROP TYPE "public"."PaymentStatus_old";
ALTER TABLE "Subscription" ALTER COLUMN "paymentStatus" SET DEFAULT 'PENDING';
COMMIT;

-- AlterTable
ALTER TABLE "Community" DROP COLUMN "price",
ADD COLUMN     "platformPlan" "PlatformPlan" NOT NULL,
ADD COLUMN     "pricingModel" "PricingModel" NOT NULL DEFAULT 'FREE';

-- AlterTable
ALTER TABLE "Membership" ADD COLUMN     "membershipTier" "MembershipTier" NOT NULL DEFAULT 'FREE',
ADD COLUMN     "pricingModelAtJoin" "PricingModel" NOT NULL DEFAULT 'FREE',
ALTER COLUMN "status" SET DEFAULT 'ACTIVE';

-- AlterTable
ALTER TABLE "Subscription" ADD COLUMN     "billingInterval" "BillingInterval",
ADD COLUMN     "externalId" TEXT,
ALTER COLUMN "subscriptionStart" SET DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "subscriptionEnd" DROP NOT NULL,
ALTER COLUMN "paymentStatus" SET DEFAULT 'PENDING';

-- CreateTable
CREATE TABLE "CommunityPricing" (
    "id" TEXT NOT NULL,
    "communityId" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "monthlyPrice" DECIMAL(65,30),
    "yearlyPrice" DECIMAL(65,30),
    "oneTimePrice" DECIMAL(65,30),
    "upgradePrice" DECIMAL(65,30),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommunityPricing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Post" (
    "id" TEXT NOT NULL,
    "communityId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "isPremium" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CommunityPricing_communityId_key" ON "CommunityPricing"("communityId");

-- CreateIndex
CREATE INDEX "Post_communityId_idx" ON "Post"("communityId");

-- CreateIndex
CREATE INDEX "Post_authorId_idx" ON "Post"("authorId");

-- CreateIndex
CREATE INDEX "Community_creatorId_idx" ON "Community"("creatorId");

-- CreateIndex
CREATE INDEX "Membership_communityId_idx" ON "Membership"("communityId");

-- CreateIndex
CREATE INDEX "Membership_userId_idx" ON "Membership"("userId");

-- CreateIndex
CREATE INDEX "Subscription_membershipId_idx" ON "Subscription"("membershipId");

-- AddForeignKey
ALTER TABLE "CommunityPricing" ADD CONSTRAINT "CommunityPricing_communityId_fkey" FOREIGN KEY ("communityId") REFERENCES "Community"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_communityId_fkey" FOREIGN KEY ("communityId") REFERENCES "Community"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
