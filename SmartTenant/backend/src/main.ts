import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  app.enableCors({origin: true,credentials: true,});
  const port = process.env.PORT || 4000;
  await app.listen(port, '0.0.0.0');
  console.log('Backend running on http://localhost:4000/api');
}
bootstrap();
