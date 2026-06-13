import {
  IsUUID,
  IsNumber,
  IsDateString,
  IsEnum,
  IsOptional,
} from 'class-validator';
import { LeaseStatus, PaymentFrequency } from '@prisma/client';

export class CreateLeaseDto {
  @IsUUID()
  tenantId!: string;

  @IsUUID()
  unitId!: string;

  @IsNumber()
  rentAmount!: number;

  @IsDateString()
  startDate!: string;

  @IsDateString()
  endDate!: string; // REQUIRED (as you requested)

  @IsEnum(PaymentFrequency)
  frequency!: PaymentFrequency; // REQUIRED

  @IsOptional()
  @IsEnum(LeaseStatus)
  status?: LeaseStatus;

  // ✅ ADD THIS
  @IsOptional()
  @IsNumber()
  depositAmount?: number;
}
