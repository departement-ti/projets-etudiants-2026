import {
  Controller,
  Get,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Response } from 'express';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('financial')
  @Roles('ADMIN', 'OWNER')
  financialReport(
    @GetUser() user: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.service.financialReport({
      orgId: user.organizationId,
      startDate,
      endDate,
    });
  }

  @Get('financial/pdf')
  @Roles('ADMIN', 'OWNER')
  async financialReportPdf(
    @GetUser() user: any,
    @Res() res: Response,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const pdfBuffer = await this.service.financialReportPdf({
      orgId: user.organizationId,
      startDate,
      endDate,
    });

    const fileName = `smarttenant-financial-report-${Date.now()}.pdf`;

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${fileName}"`,
    );
    res.send(pdfBuffer);
  }
}