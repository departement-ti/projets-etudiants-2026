import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class TestService {

  private apiUrl = 'http://localhost:8082/api/tests';

  constructor(private http: HttpClient) {}

  submitTest(studentId: number, courseId: number, answers: any): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/student/${studentId}/course/${courseId}`,
      { answers }
    );
  }

  getTestStatus(studentId: number, courseId: number): Observable<any> {
    return this.http.get<any>(
      `${this.apiUrl}/student/${studentId}/course/${courseId}/status`
    );
  }

  getStudentResults(studentId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/student/${studentId}`
    );
  }
}