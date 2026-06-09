import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CourseCommentService {

  private apiUrl = 'http://localhost:8082/api/comments';

  constructor(private http: HttpClient) {}

  addComment(
    studentId: number,
    courseId: number,
    data: any
  ): Observable<any> {

    return this.http.post(
      `${this.apiUrl}/student/${studentId}/course/${courseId}`,
      data
    );
  }

  getComments(courseId: number): Observable<any[]> {

    return this.http.get<any[]>(
      `${this.apiUrl}/course/${courseId}`
    );
  }
}