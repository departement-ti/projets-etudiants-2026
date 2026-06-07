import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';

import { BaseChartDirective } from 'ng2-charts';
import {
  Chart,
  registerables,
  ChartConfiguration,
  ChartOptions
} from 'chart.js';

Chart.register(...registerables);

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, BaseChartDirective],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class Dashboard implements OnInit {

  instructorId!: number;

  passedStudents: any[] = [];
  totalPassed = 0;

  lineChartData: ChartConfiguration<'bar'>['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Passed Students'
      }
    ]
  };

  lineChartOptions: ChartOptions<'bar'> = {
    responsive: true,
    maintainAspectRatio: false
  };

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    const id = localStorage.getItem('userId');

    if (!id) {
      console.error('Instructor ID not found in localStorage');
      return;
    }

    this.instructorId = Number(id);

    this.loadPassedStudents();
    this.loadChart();
  }

  private getHeaders(): HttpHeaders {
    const token = localStorage.getItem('token') || '';

    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }

  loadPassedStudents(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/dashboard/instructor/${this.instructorId}/passed-students`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        console.log('PASSED STUDENTS:', data);

        this.passedStudents = data;
        this.totalPassed = data.length;
      },
      error: (err) => {
        console.error('ERROR PASSED STUDENTS:', err);
      }
    });
  }

  loadChart(): void {
    this.http.get<any>(
      `http://localhost:8082/api/dashboard/instructor/${this.instructorId}/passed-chart`,
      { headers: this.getHeaders() }
    ).subscribe({
      next: (data) => {
        console.log('CHART DATA:', data);

        this.lineChartData = {
          labels: Object.keys(data),
          datasets: [
            {
              data: Object.values(data) as number[],
              label: 'Passed Students'
            }
          ]
        };
      },
      error: (err) => {
        console.error('ERROR CHART:', err);
      }
    });
  }
}