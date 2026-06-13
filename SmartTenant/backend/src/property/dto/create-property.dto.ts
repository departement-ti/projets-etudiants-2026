import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreatePropertyDto {
  @IsString()
  @IsNotEmpty()
  title!: string;   // ✅ FIX

  @IsString()
  @IsNotEmpty()
  address!: string; // ✅ FIX

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  country?: string;
}
