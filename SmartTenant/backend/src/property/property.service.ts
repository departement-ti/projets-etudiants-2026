import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';

@Injectable()
export class PropertyService {
  constructor(private prisma: PrismaService) {}

async create(orgId: string, dto: CreatePropertyDto) {
  if (!orgId) {
    throw new Error('Organization missing in token');
  }

  return this.prisma.property.create({
    data: {
      title: dto.title,
      address: dto.address,
      name: dto.name?.trim() || dto.title,
      city: dto.city ?? null,
      country: dto.country ?? null,
      organization: {
        connect: { id: orgId }, // ✅ CORRECT
      },
    },
  });
}



  async findAll(orgId: string) {
    return this.prisma.property.findMany({ where: { organizationId: orgId, isActive: true } });
  }

  async findOne(orgId: string, id: string) {
    const property = await this.prisma.property.findFirst({
      where: { id, organizationId: orgId, isActive: true },
    });
    if (!property) throw new NotFoundException('Property not found');
    return property;
  }

  async update(orgId: string, id: string, dto: UpdatePropertyDto) {
    await this.findOne(orgId, id);
    return this.prisma.property.update({
      where: { id },
      data: dto,
    });
  }

  async remove(orgId: string, id: string) {
    await this.findOne(orgId, id);
    return this.prisma.property.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
