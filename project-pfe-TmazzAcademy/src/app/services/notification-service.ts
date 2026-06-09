import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class NotificationService {

  private api = 'http://localhost:8082/api/notifications';

  constructor(private http: HttpClient) {}

  getByRole(role: string) {
    return this.http.get<any[]>(`${this.api}/role/${role}`);
  }

  getByUser(userId: number) {
    return this.http.get<any[]>(`${this.api}/user/${userId}`);
  }
}