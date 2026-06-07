import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { MonthlyPaymentService } from '../../../../services/monthly-payment-service';

@Component({
  selector: 'app-payment',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './payment.html',
  styleUrl: './payment.scss'
})
export class Payment implements OnInit {

  studentId = Number(localStorage.getItem('userId'));

  selectedFile: File | null = null;
  preview = '';

  payments: any[] = [];

  isLoading = false;
  message = '';

  constructor(
    private paymentService: MonthlyPaymentService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadPayments();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];

      const reader = new FileReader();

      reader.onload = () => {
        this.preview = reader.result as string;
      };

      reader.readAsDataURL(this.selectedFile);
    }
  }

  uploadPayment(): void {
    if (!this.selectedFile || this.isLoading) return;

    this.isLoading = true;
    this.message = '';

    this.paymentService.uploadPayment(
      this.studentId,
      this.selectedFile
    ).subscribe({
      next: () => {
        this.message = 'Payment receipt uploaded successfully';
        this.selectedFile = null;
        this.preview = '';
        this.isLoading = false;
        this.loadPayments();
      },
      error: (err: any) => {
        this.message =
          err?.error?.message ||
          err?.error ||
          'Error uploading payment receipt';

        this.isLoading = false;
      }
    });
  }

  loadPayments(): void {
    this.paymentService.getStudentPayments(this.studentId).subscribe({
      next: (data: any[]) => {
        this.payments = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  getImageUrl(path: string): string {
    return path ? `http://localhost:8082/${path}` : '';
  }
}