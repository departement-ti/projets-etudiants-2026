import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { Pool } from "pg";
import { DATABASE_URL, NODE_ENV } from "../config/env.js";

if (!DATABASE_URL) {
  throw new Error(
    'Missing DATABASE_URL. Set it in ".env" or ".env.development.local".',
  );
}

const pool = new Pool({
  connectionString: DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000,
});
const adapter = new PrismaPg(pool);

const prisma = new PrismaClient({
  adapter,
  log: ["error"],
});

const connectDB = async () => {
    try {
        await prisma.$connect();
        console.log(`Connected to database successfully in ${NODE_ENV} environment via Prisma`);
    } catch (error) {
        console.error("Error connecting to database: ", error);
        process.exit(1);
    }
};

const disconnectDB = async () => {
  await prisma.$disconnect();
  await pool.end();
};

export { connectDB, disconnectDB, prisma };