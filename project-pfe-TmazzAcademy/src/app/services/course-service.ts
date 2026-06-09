import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { isPlatformBrowser } from '@angular/common';
import { Observable } from 'rxjs';
import { Course } from '../model/course.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {

  private apiUrl = 'http://localhost:8082/api/cours';
  private commentsUrl = 'http://localhost:8082/api/comments';

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

  addCourse(instructorId: number, formData: FormData): Observable<Course> {
    return this.http.post<Course>(
      `${this.apiUrl}/instructor/${instructorId}`,
      formData,
      { headers: this.getHeaders() }
    );
  }

  getAllCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(
      this.apiUrl,
      { headers: this.getHeaders() }
    );
  }

  getCourseById(id: number): Observable<Course> {
    return this.http.get<Course>(
      `${this.apiUrl}/${id}`,
      { headers: this.getHeaders() }
    );
  }

  getCoursesByInstructor(instructorId: number): Observable<Course[]> {
    return this.http.get<Course[]>(
      `${this.apiUrl}/instructor/${instructorId}`,
      { headers: this.getHeaders() }
    );
  }

  getCourseComments(courseId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.commentsUrl}/course/${courseId}`,
      { headers: this.getHeaders() }
    );
  }

  updateCourse(id: number, data: any): Observable<Course> {
    return this.http.put<Course>(
      `${this.apiUrl}/${id}`,
      data,
      { headers: this.getHeaders() }
    );
  }

  deleteCourse(id: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/${id}`,
      { headers: this.getHeaders() }
    );
  }

  getFileUrl(path?: string): string {
    return path ? `http://localhost:8082/${path}` : '';
  }
}