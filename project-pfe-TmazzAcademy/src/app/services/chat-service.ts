import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ChatService {

  private api = 'http://localhost:8082/api/chat';

  constructor(private http: HttpClient) {}

  getMessages(): Observable<any[]> {
    return this.http.get<any[]>(`${this.api}/messages`);
  }

  sendText(data: any): Observable<any> {
    return this.http.post(`${this.api}/text`, data);
  }

  sendImage(formData: FormData): Observable<any> {
    return this.http.post(`${this.api}/image`, formData);
  }

  createPoll(data: any): Observable<any> {
    return this.http.post(`${this.api}/poll`, data);
  }

  vote(
    messageId: number,
    optionId: number,
    userId: number
  ): Observable<any> {
    return this.http.post(
      `${this.api}/poll/${messageId}/vote/${optionId}/user/${userId}`,
      {}
    );
  }

  getImageUrl(path: string): string {
    return `http://localhost:8082/${path}`;
  }
}