import { isPlatformBrowser } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Inject, Injectable, PLATFORM_ID } from '@angular/core';
import { Observable } from 'rxjs';
import { ITblStudent } from '../model/student.model';

@Injectable({
  providedIn: 'root',
})
export class StudentService {

  private baseUrl = 'http://localhost:8082/users/students';
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

  getAll(): Observable<ITblStudent[]> {
    return this.http.get<ITblStudent[]>(this.baseUrl, {
      headers: this.getHeaders()
    });
  }

  getById(id: number): Observable<ITblStudent> {
    return this.http.get<ITblStudent>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders()
    });
  }

  createStudent(data: ITblStudent): Observable<any> {
    return this.http.post(this.registerUrl, {
      name: data.name,
      lastname: data.lastname,
      email: data.email,
      password: data.password,
      tel: data.tel,
      role: 'STUDENT'
    }, {
      headers: this.getHeaders()
    });
  }

  update(id: number, data: ITblStudent): Observable<ITblStudent> {
    return this.http.put<ITblStudent>(`${this.baseUrl}/${id}`, data, {
      headers: this.getHeaders()
    });
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders()
    });
  }
}