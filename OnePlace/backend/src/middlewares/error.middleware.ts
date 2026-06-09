import type { NextFunction, Request, Response } from "express";
import { Prisma } from "@prisma/client";
const errorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let statusCode = 500;
  let message = "Server Error";

  // ✅ Prisma Known Errors
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    switch (err.code) {
      case "P2002":
        statusCode = 400;
        message = `Duplicate field value entered`;
        break;

      case "P2003":
        statusCode = 400;
        message = `Invalid foreign key reference`;
        break;

      case "P2025":
        statusCode = 404;
        message = `Resource not found`;
        break;

      default:
        statusCode = 400;
        message = err.message;
    }
  }

  // ✅ Prisma Validation Error
  if (err instanceof Prisma.PrismaClientValidationError) {
    statusCode = 400;
    message = "Invalid input data";
  }

  // ✅ Custom errors you throw manually
  if (err.statusCode) {
    statusCode = err.statusCode;
    message = err.message;
  }

  if (statusCode === 500) console.error("[500]", err);

  res.status(statusCode).json({
    success: false,
    message,
  });
};

export default errorMiddleware;
