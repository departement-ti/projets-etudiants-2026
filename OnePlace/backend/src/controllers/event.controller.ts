import type { Request, Response, NextFunction } from "express";
import * as eventService from "../services/event.service.js";

export async function listEvents(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params["communityId"] as string;
    const year = parseInt(req.query["year"] as string) || new Date().getFullYear();
    const month = parseInt(req.query["month"] as string) || new Date().getMonth() + 1;
    const events = await eventService.listEvents(communityId, year, month);
    res.json({ success: true, data: { events } });
  } catch (err) {
    next(err);
  }
}

export async function createEvent(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params["communityId"] as string;
    const event = await eventService.createEvent(communityId, req.user!.id, req.body);
    res.status(201).json({ success: true, data: { event } });
  } catch (err) {
    next(err);
  }
}

export async function deleteEvent(req: Request, res: Response, next: NextFunction) {
  try {
    await eventService.deleteEvent(req.params["eventId"] as string, req.user!.id);
    res.json({ success: true, message: "Event deleted" });
  } catch (err) {
    next(err);
  }
}
