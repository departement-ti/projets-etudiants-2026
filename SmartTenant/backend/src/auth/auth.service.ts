import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { Role, Prisma } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // -------------------------------
  // REGISTER PUBLIC USER AS TENANT
  // -------------------------------
  async register(data: {
    email: string;
    password: string;
    firstName?: string;
    lastName?: string;
  }) {
    const cleanedEmail = data.email.trim().toLowerCase();

    const existing = await this.prisma.user.findFirst({
      where: {
        email: {
          equals: cleanedEmail,
          mode: 'insensitive',
        },
      },
    });

    if (existing) {
      throw new ConflictException('User already exists');
    }

    const organization = await this.prisma.organization.findFirst({
      where: {
        isActive: true,
      },
    });

    if (!organization) {
      throw new BadRequestException(
        'No active organization found. Please seed or create an organization first.',
      );
    }

    const passwordHash = await bcrypt.hash(data.password.trim(), 10);

    const user = await this.prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          email: cleanedEmail,
          passwordHash,
          firstName: data.firstName?.trim() || null,
          lastName: data.lastName?.trim() || null,
          role: Role.TENANT,
          organizationId: organization.id,
        },
      });

      await tx.tenant.create({
  data: {
    userId: createdUser.id,
    nationalId: null,
    guarantor: Prisma.JsonNull,
  },
});

      return createdUser;
    });

    return this.signTokens(user);
  }

  // -------------------------------
  // VALIDATE USER
  // -------------------------------
  async validateUser(email: string, password: string) {
    if (!email || !password) {
      throw new UnauthorizedException('Email or password missing');
    }

    const cleanedEmail = email.trim().toLowerCase();

    const user = await this.prisma.user.findFirst({
      where: {
        email: {
          equals: cleanedEmail,
          mode: 'insensitive',
        },
      },
    });

    if (!user) return null;

    const valid = await bcrypt.compare(password.trim(), user.passwordHash);

    if (!valid) return null;

    return user;
  }

  // -------------------------------
  // LOGIN
  // -------------------------------
  async login(email: string, password: string) {
    const user = await this.validateUser(email, password);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.signTokens(user);
  }

  // -------------------------------
  // SIGN TOKENS
  // -------------------------------
  signTokens(user: {
    id: string;
    email: string;
    role: Role | string;
    organizationId: string | null;
    firstName?: string | null;
    lastName?: string | null;
  }) {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
    };

    const accessToken = this.jwtService.sign(payload, {
      expiresIn: '15m',
    });

    const refreshToken = this.jwtService.sign(
      { sub: user.id },
      { expiresIn: '7d' },
    );

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        organizationId: user.organizationId,
        firstName: user.firstName ?? null,
        lastName: user.lastName ?? null,
      },
    };
  }

  // -------------------------------
  // REFRESH TOKEN
  // -------------------------------
  async refresh(refreshToken: string) {
    try {
      const decoded = this.jwtService.verify(refreshToken);

      const user = await this.prisma.user.findUnique({
        where: { id: decoded.sub },
      });

      if (!user) {
        throw new UnauthorizedException();
      }

      return this.signTokens(user);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}