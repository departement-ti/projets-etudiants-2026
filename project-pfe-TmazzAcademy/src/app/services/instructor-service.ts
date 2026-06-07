import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { isPlatformBrowser } from '@angular/common';
import { Observable } from 'rxjs';
import { ITblInstuctor } from '../model/instructor.model';

@Injectable({
  providedIn: 'root'
})
export class InstructorService {

  private baseUrl = 'http://localhost:8082/users/instructors';
  private registerUrl = 'http://localhost:8082/auth/register';

  constructor(
    private http: HttpClient,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  private getToken(): string {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem('token') || '';
    }
    return '';
  }

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${this.getToken()}`
    });
  }

  getAll(): Observable<ITblInstuctor[]> {
    return this.http.get<ITblInstuctor[]>(this.baseUrl, {
      headers: this.getHeaders()
    });
  }

  getById(id: number): Observable<ITblInstuctor> {
    return this.http.get<ITblInstuctor>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders()
    });
  }

  createInstructor(data: ITblInstuctor): Observable<any> {
    return this.http.post(this.registerUrl, {
      name: data.name,
      lastname: data.lastname,
      email: data.email,
      password: data.password,
      tel: data.tel,
      speciality: data.speciality,
      role: 'INSTRUCTOR'
    }, {
      headers: this.getHeaders()
    });
  }

  update(id: number, data: ITblInstuctor): Observable<ITblInstuctor> {
    return this.http.put<ITblInstuctor>(`${this.baseUrl}/${id}`, data, {
      headers: this.getHeaders()
    });
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders()
    });
  }
}