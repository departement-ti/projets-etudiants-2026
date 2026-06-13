import { Module } from '@nestjs/common';
import { CopilotController } from './copilot.controller';
import { CopilotService } from './copilot.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [CopilotController],
  providers: [CopilotService, PrismaService],
})
export class CopilotModule {}