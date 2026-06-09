import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { Pool } from "pg";
import bcrypt from "bcryptjs";
import { config } from "dotenv";

config({ path: ".env" });
config({ path: ".env.development.local", override: true });

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const users = [
  { firstname: "Dalel", lastname: "User", email: "dalel@oneplace.dev", password: "Test@1234" },
];

async function main() {
  for (const u of users) {
    const hashed = await bcrypt.hash(u.password, 12);
    const created = await prisma.user.upsert({
      where: { email: u.email },
      update: { isVerified: true },
      create: {
        firstname: u.firstname,
        lastname: u.lastname,
        email: u.email,
        password: hashed,
        isVerified: true,
      },
    });
    console.log(`✓ ${created.email}`);
  }
}

main().finally(() => prisma.$disconnect());
