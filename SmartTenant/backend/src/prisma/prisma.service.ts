import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import * as pkg from '@prisma/client';  // import entire module
const { PrismaClient } = pkg;          // destructure the class

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
    console.log('Prisma connected');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
