import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class Inscription {

  private apiUrl = 'http://localhost:8082/api';

  constructor(private http: HttpClient) {}

  private getToken(): string | null {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('token');
    }
    return null;
  }

  addStudent(formData: FormData): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/inscription/student`,
      formData
    );
  }

  addInstructor(data: any): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/inscription/instructor`,
      data
    );
  }

  getStudentInscriptions(): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/inscription/students`
    );
  }

  getInstructorInscriptions(): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/inscription/instructors`
    );
  }

  acceptStudent(id: number, password: string): Observable<any> {
    const token = this.getToken();

    return this.http.post(
      `${this.apiUrl}/admin/inscriptions/students/${id}/accept`,
      { password },
      {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    );
  }

  acceptInstructor(id: number, password: string): Observable<any> {
    const token = this.getToken();

    return this.http.post(
      `${this.apiUrl}/admin/inscriptions/instructors/${id}/accept`,
      { password },
      {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    );
  }

  checkEmail(email: string): Observable<boolean> {
    return this.http.get<boolean>(
      `${this.apiUrl}/inscription/check-email?email=${email}`
    );
  }
}