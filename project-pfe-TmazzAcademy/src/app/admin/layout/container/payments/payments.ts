import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { MonthlyPaymentService } from '../../../../services/monthly-payment-service';

@Component({
  selector: 'app-payments',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './payments.html',
  styleUrl: './payments.scss'
})
export class Payments implements OnInit {

  payments: any[] = [];
  isLoading = false;

  constructor(
    private paymentService: MonthlyPaymentService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadPayments();
  }

  loadPayments(): void {
    this.paymentService.getAllPayments().subscribe({
      next: (data: any[]) => {
        this.payments = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  acceptPayment(id: number): void {
    this.isLoading = true;

    this.paymentService.acceptPayment(id).subscribe({
      next: () => {
        this.isLoading = false;
        this.loadPayments();
      },
      error: (err: any) => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  rejectPayment(id: number): void {
    this.isLoading = true;

    this.paymentService.rejectPayment(id).subscribe({
      next: () => {
        this.isLoading = false;
        this.loadPayments();
      },
      error: (err: any) => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  getImageUrl(path: string): string {
    return path ? `http://localhost:8082/${path}` : '';
  }
}