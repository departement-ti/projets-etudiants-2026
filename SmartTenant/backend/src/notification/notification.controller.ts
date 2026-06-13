import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { NotificationService } from './notification.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/get-user.decorator';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationController {
  constructor(private readonly service: NotificationService) {}

  @Get()
  findMine(
    @GetUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.service.findMine(
      user.id,
      page ? Number(page) : 1,
      limit ? Number(limit) : 30,
    );
  }

  @Get('unread-count')
  unreadCount(@GetUser() user: any) {
    return this.service.unreadCount(user.id);
  }

  @Patch(':id/read')
  markAsRead(@GetUser() user: any, @Param('id') id: string) {
    return this.service.markAsRead(user.id, id);
  }

  @Patch('read-all')
  markAllAsRead(@GetUser() user: any) {
    return this.service.markAllAsRead(user.id);
  }

  @Delete(':id')
  remove(@GetUser() user: any, @Param('id') id: string) {
    return this.service.remove(user.id, id);
  }
}