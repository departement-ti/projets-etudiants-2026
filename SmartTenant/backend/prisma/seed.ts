import {
  PrismaClient,
  Role,
  UnitStatus,
  LeaseStatus,
  PaymentFrequency,
  InvoiceStatus,
  TicketStatus,
} from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('123456', 10);

  // ======================================================
  // ORGANIZATION
  // ======================================================
  const organization = await prisma.organization.upsert({
    where: {
      slug: 'smarttenant-demo',
    },
    update: {
      name: 'SmartTenant Demo',
      isActive: true,
    },
    create: {
      name: 'SmartTenant Demo',
      slug: 'smarttenant-demo',
      isActive: true,
    },
  });

  // ======================================================
  // CLEAN OLD DEMO DATA FOR THIS ORGANIZATION
  // Keeps users/org but resets properties, leases, invoices, tickets
  // ======================================================
  await prisma.message.deleteMany({
    where: {
      ticket: {
        organizationId: organization.id,
      },
    },
  });

  await prisma.ticket.deleteMany({
    where: {
      organizationId: organization.id,
    },
  });

  await prisma.payment.deleteMany({
    where: {
      OR: [
        {
          invoice: {
            lease: {
              organizationId: organization.id,
            },
          },
        },
        {
          tenant: {
            user: {
              organizationId: organization.id,
            },
          },
        },
      ],
    },
  });

  await prisma.invoice.deleteMany({
    where: {
      lease: {
        organizationId: organization.id,
      },
    },
  });

  await prisma.lease.deleteMany({
    where: {
      organizationId: organization.id,
    },
  });

  await prisma.unit.deleteMany({
    where: {
      organizationId: organization.id,
    },
  });

  await prisma.property.deleteMany({
    where: {
      organizationId: organization.id,
    },
  });

  // ======================================================
  // USERS
  // ======================================================
  const admin = await prisma.user.upsert({
    where: {
      email: 'admin@smarttenant.com',
    },
    update: {
      passwordHash,
      role: Role.ADMIN,
      organizationId: organization.id,
      firstName: 'Admin',
      lastName: 'SmartTenant',
      phone: '+21620000001',
    },
    create: {
      email: 'admin@smarttenant.com',
      passwordHash,
      role: Role.ADMIN,
      organizationId: organization.id,
      firstName: 'Admin',
      lastName: 'SmartTenant',
      phone: '+21620000001',
    },
  });

  const owner = await prisma.user.upsert({
    where: {
      email: 'owner@smarttenant.com',
    },
    update: {
      passwordHash,
      role: Role.OWNER,
      organizationId: organization.id,
      firstName: 'Demo',
      lastName: 'Owner',
      phone: '+21620000002',
    },
    create: {
      email: 'owner@smarttenant.com',
      passwordHash,
      role: Role.OWNER,
      organizationId: organization.id,
      firstName: 'Demo',
      lastName: 'Owner',
      phone: '+21620000002',
    },
  });

  const agent = await prisma.user.upsert({
    where: {
      email: 'agent@smarttenant.com',
    },
    update: {
      passwordHash,
      role: Role.AGENT,
      organizationId: organization.id,
      firstName: 'Maintenance',
      lastName: 'Agent',
      phone: '+21620000003',
    },
    create: {
      email: 'agent@smarttenant.com',
      passwordHash,
      role: Role.AGENT,
      organizationId: organization.id,
      firstName: 'Maintenance',
      lastName: 'Agent',
      phone: '+21620000003',
    },
  });

  const tenantUser = await prisma.user.upsert({
    where: {
      email: 'tenant@smarttenant.com',
    },
    update: {
      passwordHash,
      role: Role.TENANT,
      organizationId: organization.id,
      firstName: 'Demo',
      lastName: 'Tenant',
      phone: '+21620000004',
    },
    create: {
      email: 'tenant@smarttenant.com',
      passwordHash,
      role: Role.TENANT,
      organizationId: organization.id,
      firstName: 'Demo',
      lastName: 'Tenant',
      phone: '+21620000004',
    },
  });

  const tenant = await prisma.tenant.upsert({
    where: {
      userId: tenantUser.id,
    },
    update: {
      nationalId: 'TN-DEMO-001',
      guarantor: {
        name: 'Demo Guarantor',
        phone: '+21621111111',
        relation: 'Family',
      },
      riskScore: 18,
    },
    create: {
      userId: tenantUser.id,
      nationalId: 'TN-DEMO-001',
      guarantor: {
        name: 'Demo Guarantor',
        phone: '+21621111111',
        relation: 'Family',
      },
      riskScore: 18,
    },
  });

  // ======================================================
  // PROPERTIES
  // ======================================================
  const property1 = await prisma.property.create({
    data: {
      organizationId: organization.id,
      title: 'Residence Jasmine',
      name: 'Residence Jasmine',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      country: 'Tunisia',
      description: 'Modern city-center apartment building.',
      type: 'Apartment Building',
      isActive: true,
    },
  });

  const property2 = await prisma.property.create({
    data: {
      organizationId: organization.id,
      title: 'Palm Garden Villas',
      name: 'Palm Garden Villas',
      address: 'Route Touristique',
      city: 'Sousse',
      country: 'Tunisia',
      description: 'Premium residential villas near the coast.',
      type: 'Villa Residence',
      isActive: true,
    },
  });

  // ======================================================
  // UNITS
  // ======================================================
  const unit1 = await prisma.unit.create({
    data: {
      organizationId: organization.id,
      propertyId: property1.id,
      title: 'Apartment A1',
      number: 'A1',
      floor: 1,
      bedrooms: 2,
      bathrooms: 1,
      sizeSqm: 82,
      rentAmount: 400,
      status: UnitStatus.OCCUPIED,
    },
  });

  await prisma.unit.create({
    data: {
      organizationId: organization.id,
      propertyId: property1.id,
      title: 'Apartment A2',
      number: 'A2',
      floor: 1,
      bedrooms: 1,
      bathrooms: 1,
      sizeSqm: 55,
      rentAmount: 300,
      status: UnitStatus.AVAILABLE,
    },
  });

  await prisma.unit.create({
    data: {
      organizationId: organization.id,
      propertyId: property2.id,
      title: 'Villa V1',
      number: 'V1',
      floor: 0,
      bedrooms: 3,
      bathrooms: 2,
      sizeSqm: 140,
      rentAmount: 850,
      status: UnitStatus.AVAILABLE,
    },
  });

  await prisma.unit.create({
    data: {
      organizationId: organization.id,
      propertyId: property2.id,
      title: 'Villa V2',
      number: 'V2',
      floor: 0,
      bedrooms: 4,
      bathrooms: 3,
      sizeSqm: 180,
      rentAmount: 1100,
      status: UnitStatus.MAINTENANCE,
    },
  });

  // ======================================================
  // ACTIVE LEASE
  // ======================================================
  const leaseStart = new Date('2026-05-01T00:00:00.000Z');
  const leaseEnd = new Date('2027-05-01T00:00:00.000Z');

  const lease = await prisma.lease.create({
    data: {
      organizationId: organization.id,
      tenantId: tenant.id,
      unitId: unit1.id,
      currentUnitId: unit1.id,
      startDate: leaseStart,
      endDate: leaseEnd,
      rentAmount: 400,
      frequency: PaymentFrequency.MONTHLY,
      depositAmount: 400,
      status: LeaseStatus.ACTIVE,
    },
  });

  // ======================================================
  // INVOICES + PAYMENTS
  // ======================================================
  const paidInvoice = await prisma.invoice.create({
    data: {
      leaseId: lease.id,
      amount: 400,
      dueDate: new Date('2026-06-01T00:00:00.000Z'),
      status: InvoiceStatus.PAID,
      paid: true,
      paidAt: new Date('2026-05-05T10:30:00.000Z'),
    },
  });

  await prisma.payment.create({
    data: {
      tenantId: tenant.id,
      invoiceId: paidInvoice.id,
      amount: 400,
      method: 'BANK_TRANSFER',
      provider: 'Demo Bank',
      providerRef: 'DEMO-PAID-001',
      status: 'COMPLETED',
    },
  });

  const partialInvoice = await prisma.invoice.create({
    data: {
      leaseId: lease.id,
      amount: 400,
      dueDate: new Date('2026-07-01T00:00:00.000Z'),
      status: InvoiceStatus.PARTIALLY_PAID,
      paid: false,
      paidAt: null,
    },
  });

  await prisma.payment.create({
    data: {
      tenantId: tenant.id,
      invoiceId: partialInvoice.id,
      amount: 150,
      method: 'CASH',
      provider: 'Office Payment',
      providerRef: 'DEMO-PARTIAL-001',
      status: 'COMPLETED',
    },
  });

  // ======================================================
  // TICKETS + MESSAGES
  // ======================================================
  const ticket1 = await prisma.ticket.create({
    data: {
      organizationId: organization.id,
      propertyId: property1.id,
      unitId: unit1.id,
      createdById: tenantUser.id,
      assignedToId: agent.id,
      title: 'Water leak in kitchen',
      description:
        'There is a small water leak under the kitchen sink. It needs inspection.',
      priority: 'high',
      status: TicketStatus.IN_PROGRESS,
    },
  });

  await prisma.message.create({
    data: {
      ticketId: ticket1.id,
      senderId: tenantUser.id,
      body: 'Hello, I noticed water under the kitchen sink this morning.',
    },
  });

  await prisma.message.create({
    data: {
      ticketId: ticket1.id,
      senderId: agent.id,
      body: 'Thanks for reporting it. I will inspect it today.',
    },
  });

  const ticket2 = await prisma.ticket.create({
    data: {
      organizationId: organization.id,
      propertyId: property1.id,
      unitId: unit1.id,
      createdById: tenantUser.id,
      assignedToId: admin.id,
      title: 'Air conditioner maintenance',
      description:
        'The air conditioner is making unusual noise and needs maintenance.',
      priority: 'medium',
      status: TicketStatus.OPEN,
    },
  });

  await prisma.message.create({
    data: {
      ticketId: ticket2.id,
      senderId: tenantUser.id,
      body: 'The AC works, but it makes noise after running for a few minutes.',
    },
  });

  console.log('====================================');
  console.log('Seed completed successfully');
  console.log('Organization:', organization.slug);
  console.log('------------------------------------');
  console.log('Admin:  admin@smarttenant.com  / 123456');
  console.log('Owner:  owner@smarttenant.com  / 123456');
  console.log('Agent:  agent@smarttenant.com  / 123456');
  console.log('Tenant: tenant@smarttenant.com / 123456');
  console.log('====================================');
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });