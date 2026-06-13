import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateTenantDto {
  @IsUUID()
  @IsNotEmpty()
  userId!: string; // must refer to an existing User

  @IsOptional()
  @IsString()
  nationalId?: string;

  @IsOptional()
  guarantor?: any;
}
