-- CreateEnum
CREATE TYPE "PostType" AS ENUM ('TEXT', 'IMAGE', 'VIDEO');

-- AlterTable
ALTER TABLE "Post" ADD COLUMN     "type" "PostType" NOT NULL DEFAULT 'TEXT';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "isSuspended" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "Comment" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Comment_postId_idx" ON "Comment"("postId");

-- CreateIndex
CREATE INDEX "Comment_authorId_idx" ON "Comment"("authorId");

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
