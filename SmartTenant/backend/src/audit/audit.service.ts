import { Injectable } from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type AuditActor = {
  id?: string;
  email?: string;
  role?: Role | string;
  organizationId?: string | null;
};

type AuditCreateInput = {
  actor?: AuditActor | null;
  action: string;
  resource?: string;
  resourceId?: string;
  before?: unknown;
  after?: unknown;
  metadata?: unknown;
  organizationId?: string | null;
};

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  private toJson(
    value: unknown,
  ): Prisma.InputJsonValue | typeof Prisma.JsonNull | undefined {
    if (value === undefined) return undefined;
    if (value === null) return Prisma.JsonNull;

    try {
      return JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
    } catch {
      return {
        value: String(value),
      };
    }
  }

  async log(input: AuditCreateInput) {
    const actor = input.actor ?? null;

    return this.prisma.auditLog.create({
      data: {
        organizationId: input.organizationId ?? actor?.organizationId ?? null,

        actorId: actor?.id ?? null,
        actorEmail: actor?.email ?? null,
        actorRole: actor?.role?.toString() ?? null,

        action: input.action,
        resource: input.resource ?? null,
        resourceId: input.resourceId ?? null,

        before: this.toJson(input.before),
        after: this.toJson(input.after),
        metadata: this.toJson(input.metadata),
      },
    });
  }

  async findAll(params: {
    user: AuditActor;
    page?: number;
    limit?: number;
    action?: string;
    resource?: string;
    actorId?: string;
  }) {
    const page = Math.max(params.page ?? 1, 1);
    const limit = Math.min(Math.max(params.limit ?? 25, 1), 100);
    const skip = (page - 1) * limit;

    const role = params.user.role?.toString();

    const where: Prisma.AuditLogWhereInput = {
      ...(params.action
        ? {
            action: {
              contains: params.action,
              mode: 'insensitive',
            },
          }
        : {}),

      ...(params.resource
        ? {
            resource: {
              contains: params.resource,
              mode: 'insensitive',
            },
          }
        : {}),

      ...(params.actorId
        ? {
            actorId: params.actorId,
          }
        : {}),

      ...(role === 'ADMIN'
        ? {}
        : {
            organizationId: params.user.organizationId ?? undefined,
          }),
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({
        where,
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take: limit,
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return {
      items,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  actionLabel(action: string) {
    return action
      .split('_')
      .join(' ')
      .toLowerCase()
      .replace(/\b\w/g, (char: string) => char.toUpperCase());
  }
}