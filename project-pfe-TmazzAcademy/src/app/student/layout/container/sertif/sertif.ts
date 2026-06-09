import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-sertif',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sertif.html',
  styleUrl: './sertif.scss',
})
export class Sertif implements OnInit {

  certificates: any[] = [];
  loading = true;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);

    const studentId = localStorage.getItem('userId');

    if (!studentId) {
      this.loading = false;
      return;
    }

    this.http.get<any[]>(
      `http://localhost:8082/api/certificates/student/${studentId}`
    ).subscribe({
      next: (data: any[]) => {
        this.certificates = data;
        this.loading = false;
      },
      error: (err: any) => {
        console.error(err);
        this.loading = false;
      }
    });
  }

  downloadCertificate(id: number): void {
    window.open(
      `http://localhost:8082/api/certificates/${id}/download`,
      '_blank'
    );
  }
}