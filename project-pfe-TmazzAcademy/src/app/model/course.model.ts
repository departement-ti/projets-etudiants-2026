export interface Course {
  id?: number;
  titre: string;
  description: string;
  videoPath?: string;
  pdfPath?: string;
  rating?: number;
  ratingCount?: number;
  instructor?: any;
}