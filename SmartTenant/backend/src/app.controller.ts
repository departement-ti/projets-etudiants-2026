import { Controller, Get } from '@nestjs/common';

@Controller('api')
export class AppController {
  @Get()
  getRoot() {
    return { message: 'SmartTenant API is running!' };
  }
}
