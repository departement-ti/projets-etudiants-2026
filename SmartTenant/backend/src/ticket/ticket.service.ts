import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationService } from '../notification/notification.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { UpdateTicketDto } from './dto/update-ticket.dto';
import { Role, TicketStatus } from '@prisma/client';

@Injectable()
export class TicketService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationService,
  ) {}

  private async safeAudit(input: {
    actor?: any;
    action: string;
    resource?: string;
    resourceId?: string;
    before?: unknown;
    after?: unknown;
    metadata?: unknown;
    organizationId?: string | null;
  }) {
    try {
      await this.audit.log(input);
    } catch (e) {
      console.error('Audit log failed:', e);
    }
  }

  private async safeNotify(fn: () => Promise<any>) {
    try {
      await fn();
    } catch (e) {
      console.error('Notification failed:', e);
    }
  }

  private ticketInclude() {
    return {
      createdBy: true,
      assignedTo: true,
      property: true,
      unit: true,
      messages: {
        include: {
          sender: true,
        },
        orderBy: {
          createdAt: 'asc' as const,
        },
      },
    };
  }

  private userName(user: any) {
    if (!user) return 'User';

    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;
    if (user.email) return user.email;

    return 'User';
  }

  private actorRole(actor?: any) {
    return actor?.role?.toString?.() ?? '';
  }

  private allowedAssigneeRoles() {
    return [Role.AGENT];
  }

  private assertAgentCanAccessTicket(ticket: any, actor?: any) {
    const role = this.actorRole(actor);

    if (role !== 'AGENT') return;

    if (ticket.assignedToId !== actor?.id) {
      throw new ForbiddenException(
        'Agents can only access tickets assigned to them',
      );
    }
  }

  private assertCanUpdateTicketFields(
    dto: UpdateTicketDto,
    before: any,
    actor?: any,
  ) {
    const role = this.actorRole(actor);

    if (role === 'ADMIN' || role === 'OWNER') {
      return;
    }

    if (role === 'ASSISTANT') {
      if (dto.status !== undefined) {
        const allowedStatuses: TicketStatus[] = [
          TicketStatus.OPEN,
          TicketStatus.IN_PROGRESS,
        ];

        if (!allowedStatuses.includes(dto.status)) {
          throw new ForbiddenException(
            'Assistant can only move tickets to OPEN or IN_PROGRESS',
          );
        }
      }

      return;
    }

    if (role === 'AGENT') {
      if (before.assignedToId !== actor?.id) {
        throw new ForbiddenException(
          'You can only update tickets assigned to you',
        );
      }

      const forbiddenFields = [
        dto.title,
        dto.description,
        dto.priority,
        dto.propertyId,
        dto.unitId,
        dto.assignedToId,
      ];

      if (forbiddenFields.some((value) => value !== undefined)) {
        throw new ForbiddenException('Agent can only update ticket status');
      }

      if (dto.status !== undefined) {
        const allowedStatuses: TicketStatus[] = [
          TicketStatus.IN_PROGRESS,
          TicketStatus.RESOLVED,
        ];

        if (!allowedStatuses.includes(dto.status)) {
          throw new ForbiddenException(
            'Agent can only move tickets to IN_PROGRESS or RESOLVED',
          );
        }
      }

      return;
    }

    throw new ForbiddenException('You cannot update this ticket');
  }

  private async validatePropertyAndUnit(params: {
    orgId: string;
    propertyId?: string | null;
    unitId?: string | null;
  }) {
    if (params.propertyId) {
      const property = await this.prisma.property.findFirst({
        where: {
          id: params.propertyId,
          organizationId: params.orgId,
          isActive: true,
        },
      });

      if (!property) {
        throw new NotFoundException('Property not found');
      }
    }

    if (params.unitId) {
      const unit = await this.prisma.unit.findFirst({
        where: {
          id: params.unitId,
          organizationId: params.orgId,
        },
      });

      if (!unit) {
        throw new NotFoundException('Unit not found');
      }

      if (params.propertyId && unit.propertyId !== params.propertyId) {
        throw new BadRequestException(
          'Unit does not belong to selected property',
        );
      }
    }
  }

  private async validateAssignee(userId: string, orgId: string) {
    const assignee = await this.prisma.user.findFirst({
      where: {
        id: userId,
        organizationId: orgId,
        role: {
          in: this.allowedAssigneeRoles(),
        },
      },
    });

    if (!assignee) {
      throw new BadRequestException(
        'Assignee must be an AGENT in your organization',
      );
    }

    return assignee;
  }

  async create(
    dto: CreateTicketDto,
    createdById: string,
    orgId?: string,
    actor?: any,
  ) {
    if (!orgId) {
      throw new BadRequestException('No organization attached to your account');
    }

    if (!dto.title || dto.title.trim().length === 0) {
      throw new BadRequestException('Ticket title is required');
    }

    await this.validatePropertyAndUnit({
      orgId,
      propertyId: dto.propertyId,
      unitId: dto.unitId,
    });

    const ticket = await this.prisma.ticket.create({
      data: {
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        createdById,
        organizationId: orgId,
        propertyId: dto.propertyId ?? null,
        unitId: dto.unitId ?? null,
        priority: dto.priority ?? 'medium',
      },
      include: this.ticketInclude(),
    });

    await this.safeAudit({
      actor,
      action: 'TICKET_CREATED',
      resource: 'Ticket',
      resourceId: ticket.id,
      after: ticket,
      organizationId: orgId,
      metadata: {
        title: ticket.title,
        priority: ticket.priority,
        propertyId: ticket.propertyId,
        unitId: ticket.unitId,
      },
    });

    await this.safeNotify(() =>
      this.notifications.notifyOrganizationStaff({
        organizationId: orgId,
        excludeUserId: createdById,
        roles: ['ADMIN', 'OWNER', 'ASSISTANT'],
        title: 'New maintenance ticket',
        body: `${this.userName(ticket.createdBy)} created a ticket: ${ticket.title}`,
        type: 'TICKET',
        resource: 'Ticket',
        resourceId: ticket.id,
        metadata: {
          ticketId: ticket.id,
          title: ticket.title,
          priority: ticket.priority,
          createdById,
        },
      }),
    );

    return ticket;
  }

  async findAllByOrganization(orgId: string) {
    return this.prisma.ticket.findMany({
      where: {
        organizationId: orgId,
      },
      include: this.ticketInclude(),
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findAssignedToAgent(orgId: string, agentUserId: string) {
    return this.prisma.ticket.findMany({
      where: {
        organizationId: orgId,
        assignedToId: agentUserId,
      },
      include: this.ticketInclude(),
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string, orgId: string) {
    const ticket = await this.prisma.ticket.findFirst({
      where: {
        id,
        organizationId: orgId,
      },
      include: this.ticketInclude(),
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    return ticket;
  }

  async findOneForUser(id: string, user: any) {
    const role = user.role?.toString();

    if (role === 'TENANT') {
      const ticket = await this.prisma.ticket.findFirst({
        where: {
          id,
          createdById: user.id,
        },
        include: this.ticketInclude(),
      });

      if (!ticket) {
        throw new NotFoundException('Ticket not found');
      }

      return ticket;
    }

    if (role === 'AGENT') {
      const ticket = await this.prisma.ticket.findFirst({
        where: {
          id,
          organizationId: user.organizationId,
          assignedToId: user.id,
        },
        include: this.ticketInclude(),
      });

      if (!ticket) {
        throw new NotFoundException('Ticket not found');
      }

      return ticket;
    }

    if (role === 'ADMIN' || role === 'OWNER' || role === 'ASSISTANT') {
      const ticket = await this.prisma.ticket.findFirst({
        where: {
          id,
          organizationId: user.organizationId,
        },
        include: this.ticketInclude(),
      });

      if (!ticket) {
        throw new NotFoundException('Ticket not found');
      }

      return ticket;
    }

    throw new NotFoundException('Ticket not found');
  }

  async addMessage(
    ticketId: string,
    body: string,
    userId: string,
    orgId?: string,
    actor?: any,
  ) {
    if (!body || body.trim().length === 0) {
      throw new BadRequestException('Message body is required');
    }

    const ticket = await this.prisma.ticket.findFirst({
      where: {
        id: ticketId,
        ...(orgId ? { organizationId: orgId } : {}),
      },
      include: {
        createdBy: true,
        assignedTo: true,
      },
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    if (
      (actor?.role === Role.TENANT || actor?.role === 'TENANT') &&
      ticket.createdById !== userId
    ) {
      throw new ForbiddenException('You can only reply to your own tickets');
    }

    this.assertAgentCanAccessTicket(ticket, actor);

    const message = await this.prisma.message.create({
      data: {
        ticketId,
        senderId: userId,
        body: body.trim(),
      },
      include: {
        sender: true,
      },
    });

    await this.safeAudit({
      actor,
      action: 'TICKET_MESSAGE_ADDED',
      resource: 'Ticket',
      resourceId: ticketId,
      after: message,
      organizationId: ticket.organizationId,
      metadata: {
        ticketTitle: ticket.title,
        messageId: message.id,
        bodyPreview: body.trim().slice(0, 120),
      },
    });

    const senderRole = message.sender.role?.toString();

    if (senderRole === 'TENANT') {
      const notifyUserIds = new Set<string>();

      if (ticket.assignedToId && ticket.assignedToId !== userId) {
        notifyUserIds.add(ticket.assignedToId);
      }

      const staffUsers = await this.prisma.user.findMany({
        where: {
          organizationId: ticket.organizationId,
          role: {
            in: [Role.ADMIN, Role.OWNER, Role.ASSISTANT],
          },
          id: {
            not: userId,
          },
        },
        select: {
          id: true,
        },
      });

      for (const staff of staffUsers) {
        notifyUserIds.add(staff.id);
      }

      await this.safeNotify(() =>
        this.notifications.createMany(
          Array.from(notifyUserIds).map((targetUserId) => ({
            userId: targetUserId,
            organizationId: ticket.organizationId,
            title: 'New tenant message',
            body: `${this.userName(message.sender)} replied on: ${ticket.title}`,
            type: 'MESSAGE',
            resource: 'Ticket',
            resourceId: ticket.id,
            metadata: {
              ticketId: ticket.id,
              messageId: message.id,
              senderId: userId,
              ticketTitle: ticket.title,
              bodyPreview: body.trim().slice(0, 120),
            },
          })),
        ),
      );
    } else if (ticket.createdById !== userId) {
      await this.safeNotify(() =>
        this.notifications.create({
          userId: ticket.createdById,
          organizationId: ticket.organizationId,
          title: 'New reply on your ticket',
          body: `${this.userName(message.sender)} replied on: ${ticket.title}`,
          type: 'MESSAGE',
          resource: 'Ticket',
          resourceId: ticket.id,
          metadata: {
            ticketId: ticket.id,
            messageId: message.id,
            senderId: userId,
            ticketTitle: ticket.title,
            bodyPreview: body.trim().slice(0, 120),
          },
        }),
      );
    }

    return message;
  }

  async assign(
    ticketId: string,
    assignedToId: string,
    orgId: string,
    actor?: any,
  ) {
    const before = await this.findOne(ticketId, orgId);
    const user = await this.validateAssignee(assignedToId, orgId);

    const updated = await this.prisma.ticket.update({
      where: {
        id: ticketId,
      },
      data: {
        assignedToId,
        status: TicketStatus.IN_PROGRESS,
      },
      include: this.ticketInclude(),
    });

    await this.safeAudit({
      actor,
      action: 'TICKET_ASSIGNED',
      resource: 'Ticket',
      resourceId: ticketId,
      before,
      after: updated,
      organizationId: orgId,
      metadata: {
        ticketTitle: updated.title,
        assignedToId,
        assignedToEmail: user.email,
        previousAssignedToId: before.assignedToId,
      },
    });

    if (before.status !== updated.status) {
      await this.safeAudit({
        actor,
        action: 'TICKET_STATUS_UPDATED',
        resource: 'Ticket',
        resourceId: ticketId,
        before: {
          status: before.status,
        },
        after: {
          status: updated.status,
        },
        organizationId: orgId,
        metadata: {
          ticketTitle: updated.title,
          reason: 'Assignment automatically moved ticket to IN_PROGRESS',
        },
      });
    }

    await this.safeNotify(() =>
      this.notifications.create({
        userId: assignedToId,
        organizationId: orgId,
        title: 'Ticket assigned to you',
        body: `You have been assigned to: ${updated.title}`,
        type: 'ASSIGNMENT',
        resource: 'Ticket',
        resourceId: updated.id,
        metadata: {
          ticketId: updated.id,
          ticketTitle: updated.title,
          assignedById: actor?.id,
          assignedByEmail: actor?.email,
        },
      }),
    );

    if (updated.createdById !== assignedToId) {
      await this.safeNotify(() =>
        this.notifications.create({
          userId: updated.createdById,
          organizationId: orgId,
          title: 'Your ticket was assigned',
          body: `${updated.title} was assigned to ${this.userName(user)}`,
          type: 'TICKET',
          resource: 'Ticket',
          resourceId: updated.id,
          metadata: {
            ticketId: updated.id,
            ticketTitle: updated.title,
            assignedToId,
            assignedToEmail: user.email,
          },
        }),
      );
    }

    return updated;
  }

  async update(
    ticketId: string,
    dto: UpdateTicketDto,
    orgId: string,
    actor?: any,
  ) {
    const before = await this.findOne(ticketId, orgId);

    this.assertCanUpdateTicketFields(dto, before, actor);

    const effectivePropertyId =
      dto.propertyId === undefined ? before.propertyId : dto.propertyId;

    const effectiveUnitId =
      dto.unitId === undefined ? before.unitId : dto.unitId;

    await this.validatePropertyAndUnit({
      orgId,
      propertyId: effectivePropertyId,
      unitId: effectiveUnitId,
    });

    if (dto.assignedToId) {
      await this.validateAssignee(dto.assignedToId, orgId);
    }

    const updated = await this.prisma.ticket.update({
      where: {
        id: ticketId,
      },
      data: {
        title:
          dto.title === undefined ? undefined : dto.title.trim() || before.title,
        description:
          dto.description === undefined
            ? undefined
            : dto.description.trim() || null,
        status: dto.status,
        priority: dto.priority,
        propertyId: dto.propertyId,
        unitId: dto.unitId,
        assignedToId: dto.assignedToId,
      },
      include: this.ticketInclude(),
    });

    if (before.status !== updated.status) {
      await this.safeAudit({
        actor,
        action: 'TICKET_STATUS_UPDATED',
        resource: 'Ticket',
        resourceId: ticketId,
        before: {
          status: before.status,
        },
        after: {
          status: updated.status,
        },
        organizationId: orgId,
        metadata: {
          ticketTitle: updated.title,
        },
      });

      if (updated.createdById !== actor?.id) {
        await this.safeNotify(() =>
          this.notifications.create({
            userId: updated.createdById,
            organizationId: orgId,
            title: 'Ticket status updated',
            body: `${updated.title} is now ${updated.status}`,
            type: 'STATUS',
            resource: 'Ticket',
            resourceId: updated.id,
            metadata: {
              ticketId: updated.id,
              ticketTitle: updated.title,
              previousStatus: before.status,
              newStatus: updated.status,
            },
          }),
        );
      }
    }

    if (before.priority !== updated.priority) {
      await this.safeAudit({
        actor,
        action: 'TICKET_PRIORITY_UPDATED',
        resource: 'Ticket',
        resourceId: ticketId,
        before: {
          priority: before.priority,
        },
        after: {
          priority: updated.priority,
        },
        organizationId: orgId,
        metadata: {
          ticketTitle: updated.title,
        },
      });
    }

    if (before.assignedToId !== updated.assignedToId) {
      await this.safeAudit({
        actor,
        action: 'TICKET_ASSIGNED',
        resource: 'Ticket',
        resourceId: ticketId,
        before: {
          assignedToId: before.assignedToId,
        },
        after: {
          assignedToId: updated.assignedToId,
        },
        organizationId: orgId,
        metadata: {
          ticketTitle: updated.title,
        },
      });

      if (updated.assignedToId) {
        await this.safeNotify(() =>
          this.notifications.create({
            userId: updated.assignedToId!,
            organizationId: orgId,
            title: 'Ticket assigned to you',
            body: `You have been assigned to: ${updated.title}`,
            type: 'ASSIGNMENT',
            resource: 'Ticket',
            resourceId: updated.id,
            metadata: {
              ticketId: updated.id,
              ticketTitle: updated.title,
              assignedById: actor?.id,
              assignedByEmail: actor?.email,
            },
          }),
        );
      }
    }

    await this.safeAudit({
      actor,
      action: 'TICKET_UPDATED',
      resource: 'Ticket',
      resourceId: ticketId,
      before,
      after: updated,
      organizationId: orgId,
      metadata: {
        ticketTitle: updated.title,
      },
    });

    return updated;
  }

  async remove(ticketId: string, orgId: string, actor?: any) {
    const before = await this.findOne(ticketId, orgId);

    await this.prisma.message.deleteMany({
      where: {
        ticketId,
      },
    });

    const deleted = await this.prisma.ticket.delete({
      where: {
        id: ticketId,
      },
    });

    await this.safeAudit({
      actor,
      action: 'TICKET_DELETED',
      resource: 'Ticket',
      resourceId: ticketId,
      before,
      after: deleted,
      organizationId: orgId,
      metadata: {
        ticketTitle: before.title,
        messageCount: before.messages.length,
      },
    });

    if (before.createdById !== actor?.id) {
      await this.safeNotify(() =>
        this.notifications.create({
          userId: before.createdById,
          organizationId: orgId,
          title: 'Ticket deleted',
          body: `Your ticket was deleted: ${before.title}`,
          type: 'WARNING',
          resource: 'Ticket',
          resourceId: ticketId,
          metadata: {
            ticketId,
            ticketTitle: before.title,
            deletedById: actor?.id,
            deletedByEmail: actor?.email,
          },
        }),
      );
    }

    return deleted;
  }

  async findByUserId(userId: string) {
    return this.prisma.ticket.findMany({
      where: {
        createdById: userId,
      },
      include: this.ticketInclude(),
      orderBy: {
        createdAt: 'desc',
      },
    });
  }
}