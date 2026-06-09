import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { NewInstructor } from '../../../../model/NewInstructor.model';
import { Inscription } from '../../../../services/inscription';

@Component({
  selector: 'app-inscript',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './inscript.html',
  styleUrl: './inscript.scss'
})
export class Inscript {

  showPopup = false;
  selectedType: 'student' | 'instructor' | null = null;

  successMessage = '';
  isLoading = false;

  emailChecking = false;
  emailExists = false;

  receiptFile: File | null = null;
  receiptPreview = '';

  student = {
    name: '',
    lastname: '',
    email: '',
    tel: ''
  };

  instructor: NewInstructor = {
    name: '',
    lastname: '',
    email: '',
    tel: '',
    speciality: ''
  };

  constructor(
    private inscriptionService: Inscription,
    private router: Router
  ) {}

  openPopup(type: 'student' | 'instructor') {
    this.selectedType = type;
    this.showPopup = true;
    this.successMessage = '';
    this.isLoading = false;
    this.emailChecking = false;
    this.emailExists = false;
  }

  closePopup() {
    this.showPopup = false;
    this.selectedType = null;
    this.isLoading = false;
    this.emailChecking = false;
    this.emailExists = false;
    this.receiptFile = null;
    this.receiptPreview = '';
  }

  checkEmailLive(email: string) {
    this.emailExists = false;

    if (!email || !email.includes('@')) return;

    this.emailChecking = true;

    this.inscriptionService.checkEmail(email).subscribe({
      next: (exists) => {
        this.emailExists = exists;
        this.emailChecking = false;
      },
      error: () => {
        this.emailChecking = false;
      }
    });
  }

  onReceiptSelected(event: Event) {
    const input = event.target as HTMLInputElement;

    if (input.files && input.files.length > 0) {
      this.receiptFile = input.files[0];

      const reader = new FileReader();
      reader.onload = () => {
        this.receiptPreview = reader.result as string;
      };

      reader.readAsDataURL(this.receiptFile);
    }
  }

  submitStudent() {
    if (
      this.isLoading ||
      this.emailExists ||
      this.emailChecking ||
      !this.receiptFile
    ) return;

    this.successMessage = '';
    this.isLoading = true;

    const formData = new FormData();

    formData.append('name', this.student.name);
    formData.append('lastname', this.student.lastname);
    formData.append('email', this.student.email);
    formData.append('tel', this.student.tel);
    formData.append('recuPaiement', this.receiptFile);

    this.inscriptionService.addStudent(formData).subscribe({
      next: () => {
        this.successMessage = 'Student inscription sent successfully';
        this.resetStudent();
        this.closePopup();
        this.router.navigate(['/']);
      },
      error: (err) => {
        if (err.status === 409) {
          this.emailExists = true;
        }

        this.isLoading = false;
      }
    });
  }

  submitInstructor() {
    if (this.isLoading || this.emailExists || this.emailChecking) return;

    this.successMessage = '';
    this.isLoading = true;

    this.inscriptionService.addInstructor(this.instructor).subscribe({
      next: () => {
        this.successMessage = 'Instructor inscription sent successfully';
        this.resetInstructor();
        this.closePopup();
        this.router.navigate(['/']);
      },
      error: (err) => {
        if (err.status === 409) {
          this.emailExists = true;
        }

        this.isLoading = false;
      }
    });
  }

  resetStudent() {
    this.student = {
      name: '',
      lastname: '',
      email: '',
      tel: ''
    };

    this.receiptFile = null;
    this.receiptPreview = '';
  }

  resetInstructor() {
    this.instructor = {
      name: '',
      lastname: '',
      email: '',
      tel: '',
      speciality: ''
    };
  }
}