// types/cookie-parser.d.ts
declare module "cookie-parser" {
  import { RequestHandler } from "express";

  function cookieParser(secret?: string | Array<string>, options?: any): RequestHandler;
  export = cookieParser;
}
