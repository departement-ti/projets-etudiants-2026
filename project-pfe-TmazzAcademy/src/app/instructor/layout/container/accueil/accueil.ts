import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Component({
  selector: 'app-accueil',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './accueil.html',
  styleUrl: './accueil.scss'
})
export class Accueil implements OnInit {

  instructorId = Number(localStorage.getItem('userId'));

  instructor: any = null;

  totalCourses = 0;
  activeCourses = 0;
  inactiveCourses = 0;

  isLoading = true;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadInstructor();
    this.loadCourseStats();
  }

  getHeaders(): HttpHeaders {
    const token = localStorage.getItem('token') || '';

    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }

  loadInstructor(): void {
    this.http.get<any>(
      `http://localhost:8082/users/instructors/${this.instructorId}`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        this.instructor = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  loadCourseStats(): void {
    this.http.get<any>(
      `http://localhost:8082/api/cours/stats/instructor/${this.instructorId}`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        this.totalCourses = data.total || 0;
        this.activeCourses = data.active || 0;
        this.inactiveCourses = data.inactive || 0;
      },
      error: (err) => {
        console.error(err);
        this.totalCourses = 0;
        this.activeCourses = 0;
        this.inactiveCourses = 0;
      }
    });
  }

  get fullName(): string {
    return `${this.instructor?.name || ''} ${this.instructor?.lastname || ''}`;
  }
}