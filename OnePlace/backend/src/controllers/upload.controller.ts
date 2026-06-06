import type { Request, Response, NextFunction } from "express";
import { createPresignedUpload, type UploadFolder } from "../services/upload.service.js";

const VALID_FOLDERS: UploadFolder[] = ["avatars", "courses", "lessons", "attachments", "posts", "communities"];

// POST /api/v1/upload/presign
export async function presign(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { filename, contentType, folder } = req.body as {
      filename: string;
      contentType: string;
      folder: UploadFolder;
    };

    if (!filename || !contentType || !folder) {
      res.status(400).json({ success: false, message: "filename, contentType, and folder are required" });
      return;
    }

    if (!VALID_FOLDERS.includes(folder)) {
      res.status(400).json({ success: false, message: `folder must be one of: ${VALID_FOLDERS.join(", ")}` });
      return;
    }

    const result = await createPresignedUpload({ filename, contentType, folder });
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}
