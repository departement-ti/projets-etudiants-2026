import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class QuestionTestService {

  private apiUrl = 'http://localhost:8082/api/questions';

  constructor(private http: HttpClient) {}

  addQuestion(courseId: number, data: any): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/course/${courseId}`,
      data
    );
  }

  getQuestions(courseId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/course/${courseId}`
    );
  }

  updateQuestion(id: number, data: any) {
    return this.http.put(
      `${this.apiUrl}/${id}`,
      data
    );
  }

  deleteQuestion(id: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/${id}`
    );
  }
}