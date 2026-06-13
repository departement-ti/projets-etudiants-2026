/*
  Warnings:

  - You are about to drop the column `updatedAt` on the `Payment` table. All the data in the column will be lost.
  - Made the column `invoiceId` on table `Payment` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_invoiceId_fkey";

-- DropIndex
DROP INDEX "Payment_invoiceId_key";

-- AlterTable
ALTER TABLE "Payment" DROP COLUMN "updatedAt",
ALTER COLUMN "invoiceId" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
