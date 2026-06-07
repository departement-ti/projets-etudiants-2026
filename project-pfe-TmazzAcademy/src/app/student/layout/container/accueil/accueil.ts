import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-accueil',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './accueil.html',
  styleUrl: './accueil.scss'
})
export class Accueil implements OnInit {

  studentId = Number(localStorage.getItem('userId'));

  student: any = null;

  favorites: any[] = [];
  certificates: any[] = [];
  results: any[] = [];

  isLoading = true;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadStudent();
    this.loadFavorites();
    this.loadCertificates();
    this.loadResults();
  }

  loadStudent(): void {
    this.http.get<any>(
      `http://localhost:8082/users/students/${this.studentId}`
    ).subscribe({
      next: (data) => {
        this.student = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  loadFavorites(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/favorites/student/${this.studentId}`
    ).subscribe({
      next: (data) => {
        this.favorites = data;
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  loadCertificates(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/certificates/student/${this.studentId}`
    ).subscribe({
      next: (data) => {
        this.certificates = data;
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  loadResults(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/tests/student/${this.studentId}`
    ).subscribe({
      next: (data) => {
        this.results = data;
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  get fullName(): string {
    return `${this.student?.name || ''} ${this.student?.lastname || ''}`;
  }

  get passedTests(): number {
    return this.results.filter(r => r.score >= 10).length;
  }

  get failedTests(): number {
    return this.results.filter(r => r.score < 10).length;
  }
}