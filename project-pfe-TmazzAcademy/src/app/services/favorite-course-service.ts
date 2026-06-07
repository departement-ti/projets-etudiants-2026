import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class FavoriteCourseService {

  private apiUrl = 'http://localhost:8082/api/favorites';

  constructor(private http: HttpClient) {}

  addFavorite(studentId: number, courseId: number): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/student/${studentId}/course/${courseId}`,
      {}
    );
  }

  removeFavorite(studentId: number, courseId: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/student/${studentId}/course/${courseId}`
    );
  }

  isFavorite(studentId: number, courseId: number): Observable<boolean> {
    return this.http.get<boolean>(
      `${this.apiUrl}/student/${studentId}/course/${courseId}/check`
    );
  }

  getFavorites(studentId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/student/${studentId}`
    );
  }
}