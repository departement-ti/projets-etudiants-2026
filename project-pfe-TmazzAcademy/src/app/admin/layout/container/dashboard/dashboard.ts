import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';

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

  passedStudents: any[] = [];

  totalPassed = 0;
  totalCertificates = 0;

  certificatesChartData: ChartConfiguration<'bar'>['data'] = {
    labels: [],
    datasets: [{ data: [], label: 'Certificates' }]
  };

  activeInstructorsChartData: ChartConfiguration<'line'>['data'] = {
    labels: [],
    datasets: [{ data: [], label: 'Active Instructors' }]
  };

  chartOptions: ChartOptions<any> = {
    responsive: true,
    maintainAspectRatio: false
  };

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadPassedStudents();
    this.loadCertificatesChart();
    this.loadActiveInstructorsChart();
  }

  loadPassedStudents(): void {
    this.http.get<any[]>('http://localhost:8082/api/dashboard/admin/passed-students')
      .subscribe({
        next: (data: any[]) => {
          this.passedStudents = data;
          this.totalPassed = data.length;
        },
        error: (err: any) => {
          console.error(err);
        }
      });
  }

  loadCertificatesChart(): void {
    this.http.get<any>('http://localhost:8082/api/dashboard/admin/certificates-chart')
      .subscribe({
        next: (data: any) => {
          this.totalCertificates = Object.values(data)
            .reduce((sum: number, value: any) => sum + Number(value), 0);

          this.certificatesChartData = {
            labels: Object.keys(data),
            datasets: [
              {
                data: Object.values(data) as number[],
                label: 'Certificates'
              }
            ]
          };
        },
        error: (err: any) => {
          console.error(err);
        }
      });
  }

  loadActiveInstructorsChart(): void {
    this.http.get<any>('http://localhost:8082/api/dashboard/admin/active-instructors-chart')
      .subscribe({
        next: (data: any) => {
          this.activeInstructorsChartData = {
            labels: Object.keys(data),
            datasets: [
              {
                data: Object.values(data) as number[],
                label: 'Active Instructors'
              }
            ]
          };
        },
        error: (err: any) => {
          console.error(err);
        }
      });
  }
}