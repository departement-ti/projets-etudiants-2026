import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class MonthlyPaymentService {

  private api = 'http://localhost:8082/api/monthly-payments';

  constructor(private http: HttpClient) {}

  uploadPayment(studentId: number, file: File) {
    const formData = new FormData();
    formData.append('image', file);

    return this.http.post<any>(
      `${this.api}/student/${studentId}`,
      formData
    );
  }

  getStudentPayments(studentId: number) {
    return this.http.get<any[]>(
      `${this.api}/student/${studentId}`
    );
  }

  getAllPayments() {
    return this.http.get<any[]>(
      this.api
    );
  }

  acceptPayment(id: number) {
    return this.http.put<any>(
      `${this.api}/${id}/accept`,
      {}
    );
  }

  rejectPayment(id: number) {
    return this.http.put<any>(
      `${this.api}/${id}/reject`,
      {}
    );
  }
}