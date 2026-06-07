import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Component({
  selector: 'app-sertif',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sertif.html',
  styleUrl: './sertif.scss'
})
export class Sertif implements OnInit {

  passedStudents: any[] = [];
  failedStudents: any[] = [];

  isLoading = false;
  errorMessage = '';

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadResults();
  }

  private getHeaders(): HttpHeaders {
    const token = localStorage.getItem('token') || '';

    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }

  loadResults(): void {
    const instructorId = Number(localStorage.getItem('userId'));

    if (!instructorId) {
      this.errorMessage = 'Instructor ID not found';
      return;
    }

    this.isLoading = true;

    this.http.get<any[]>(
      `http://localhost:8082/api/dashboard/instructor/${instructorId}/passed-students`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        this.passedStudents = data.map(r => ({
          studentName: `${r.student?.name || ''} ${r.student?.lastname || ''}`,
          courseTitle: r.cours?.titre,
          score: r.score
        }));

        this.loadFailedStudents(instructorId);
      },
      error: (err) => {
        console.error(err);
        this.errorMessage = 'Error loading certified students';
        this.isLoading = false;
      }
    });
  }

  loadFailedStudents(instructorId: number): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/dashboard/instructor/${instructorId}/failed-students`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        this.failedStudents = data.map(r => ({
          studentName: `${r.student?.name || ''} ${r.student?.lastname || ''}`,
          courseTitle: r.cours?.titre,
          score: r.score
        }));

        this.isLoading = false;
      },
      error: (err) => {
        console.error(err);
        this.errorMessage = 'Error loading failed students';
        this.isLoading = false;
      }
    });
  }
}