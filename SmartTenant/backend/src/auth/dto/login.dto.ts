import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail()
  email!: string;        // ✅ tell TS: "it WILL be assigned"

  @IsString()
  @MinLength(6)
  password!: string;     // ✅
}
