import { UnitStatus } from '@prisma/client';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsEnum,
} from 'class-validator';

export class CreateUnitDto {
  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsNumber()
  rentAmount!: number;

  @IsOptional()
  @IsNumber()
  floor?: number;

  @IsOptional()
  @IsNumber()
  bedrooms?: number;

  @IsOptional()
  @IsNumber()
  bathrooms?: number;

  @IsOptional()
  @IsString()
  number?: string;

  @IsOptional()
  @IsNumber()
  sizeSqm?: number;

  @IsOptional()
  @IsEnum(UnitStatus) // ✅ FIX
  status?: UnitStatus;
}
