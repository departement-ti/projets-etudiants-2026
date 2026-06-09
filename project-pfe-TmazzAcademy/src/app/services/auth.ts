import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class Auth {

  private API = 'http://localhost:8082/auth';

  constructor(private http: HttpClient) {}

  // LOGIN
  login(data: any) {
    return this.http.post<any>(`${this.API}/login`, data);
  }

  // REGISTER (NEW)
  register(data: any) {
    return this.http.post<any>(`${this.API}/register`, data);
  }

  saveToken(token: string) {
    localStorage.setItem('token', token);
  }

  saveRole(role: string) {
    localStorage.setItem('role', role);
  }

  getRole() {
    return localStorage.getItem('role');
  }
}