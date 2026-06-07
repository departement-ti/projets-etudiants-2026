import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ChatbotService {

  private apiUrl = 'http://localhost:8082/api/chatbot';

  constructor(private http: HttpClient) {}

  ask(message: string, role: string): Observable<any> {

    return this.http.post<any>(this.apiUrl, {
      message,
      role
    });
  }
}