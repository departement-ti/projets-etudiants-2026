import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type CreateNotificationInput = {
  userId: string;
  organizationId?: string | null;
  title: string;
  body: string;
  type?: string;
  resource?: string;
  resourceId?: string;
  actionUrl?: string;
  metadata?: unknown;
};

@Injectable()
export class NotificationService {
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

  async create(input: CreateNotificationInput) {
    return this.prisma.notification.create({
      data: {
        userId: input.userId,
        organizationId: input.organizationId ?? null,
        title: input.title,
        body: input.body,
        type: input.type ?? 'INFO',
        resource: input.resource ?? null,
        resourceId: input.resourceId ?? null,
        actionUrl: input.actionUrl ?? null,
        metadata: this.toJson(input.metadata),
      },
    });
  }

  async createMany(inputs: CreateNotificationInput[]) {
    if (inputs.length === 0) return { count: 0 };

    return this.prisma.notification.createMany({
      data: inputs.map((input) => ({
        userId: input.userId,
        organizationId: input.organizationId ?? null,
        title: input.title,
        body: input.body,
        type: input.type ?? 'INFO',
        resource: input.resource ?? null,
        resourceId: input.resourceId ?? null,
        actionUrl: input.actionUrl ?? null,
        metadata: this.toJson(input.metadata),
      })),
      skipDuplicates: false,
    });
  }

  async notifyOrganizationStaff(params: {
    organizationId: string;
    title: string;
    body: string;
    type?: string;
    resource?: string;
    resourceId?: string;
    excludeUserId?: string;
    roles?: string[];
    metadata?: unknown;
  }) {
    const roles = params.roles ?? ['ADMIN', 'OWNER'];

    const users = await this.prisma.user.findMany({
      where: {
        organizationId: params.organizationId,
        role: {
          in: roles as any,
        },
        ...(params.excludeUserId
          ? {
              id: {
                not: params.excludeUserId,
              },
            }
          : {}),
      },
      select: {
        id: true,
      },
    });

    return this.createMany(
      users.map((user) => ({
        userId: user.id,
        organizationId: params.organizationId,
        title: params.title,
        body: params.body,
        type: params.type,
        resource: params.resource,
        resourceId: params.resourceId,
        metadata: params.metadata,
      })),
    );
  }

  async findMine(userId: string, page = 1, limit = 30) {
    const safePage = Math.max(page, 1);
    const safeLimit = Math.min(Math.max(limit, 1), 100);
    const skip = (safePage - 1) * safeLimit;

    const [items, total, unread] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where: {
          userId,
        },
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take: safeLimit,
      }),
      this.prisma.notification.count({
        where: {
          userId,
        },
      }),
      this.prisma.notification.count({
        where: {
          userId,
          isRead: false,
        },
      }),
    ]);

    return {
      items,
      meta: {
        page: safePage,
        limit: safeLimit,
        total,
        totalPages: Math.ceil(total / safeLimit),
        unread,
      },
    };
  }

  async unreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
      },
    });

    return { count };
  }

  async markAsRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id,
        userId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: {
        id,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async remove(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id,
        userId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.delete({
      where: {
        id,
      },
    });
  }
}