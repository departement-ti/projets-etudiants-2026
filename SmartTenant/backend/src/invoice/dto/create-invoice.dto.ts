import { IsDateString, IsNotEmpty, IsNumber, IsUUID } from 'class-validator';

export class CreateInvoiceDto {
  @IsUUID()
  @IsNotEmpty()
  leaseId!: string;

  @IsNumber()
  amount!: number;

  @IsDateString()
  dueDate!: string;
}