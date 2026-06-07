import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-accueil',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './accueil.html',
  styleUrl: './accueil.scss',
})
export class Accueil implements OnInit {

  students: any[] = [];
  instructors: any[] = [];
  courses: any[] = [];
  payments: any[] = [];

  isLoading = true;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading = true;

    this.http.get<any[]>('http://localhost:8082/users/students').subscribe({
      next: (data) => {
        this.students = data;
        this.checkLoading();
      },
      error: () => this.checkLoading()
    });

    this.http.get<any[]>('http://localhost:8082/users/instructors').subscribe({
      next: (data) => {
        this.instructors = data;
        this.checkLoading();
      },
      error: () => this.checkLoading()
    });

    this.http.get<any[]>('http://localhost:8082/api/cours').subscribe({
      next: (data) => {
        this.courses = data;
        this.checkLoading();
      },
      error: () => this.checkLoading()
    });

    this.http.get<any[]>('http://localhost:8082/api/monthly-payments').subscribe({
      next: (data) => {
        this.payments = data;
        this.checkLoading();
      },
      error: () => this.checkLoading()
    });
  }

  checkLoading(): void {
    this.isLoading = false;
  }

  get pendingPayments(): number {
    return this.payments.filter(p => p.status === 'PENDING').length;
  }
}