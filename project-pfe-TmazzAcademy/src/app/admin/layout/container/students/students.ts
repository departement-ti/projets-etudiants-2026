import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, NgZone, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Inscription } from '../../../../services/inscription';

@Component({
  selector: 'app-students',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './students.html',
  styleUrl: './students.scss',
})
export class Students implements OnInit {

  students: any[] = [];
  selectedStudent: any = null;

  showPopup = false;
  password = '';
  isLoading = false;

  constructor(
    private inscriptionService: Inscription,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    this.loadStudents();
  }

  loadStudents() {
    this.inscriptionService.getStudentInscriptions().subscribe({
      next: (data) => {
        console.log('STUDENTS DATA:', data);

        this.zone.run(() => {
          this.students = [...data];
          this.cdr.detectChanges();
        });
      },
      error: (err) => {
        console.error('ERROR GET STUDENTS:', err);
      }
    });
  }

  getReceiptUrl(path: string): string {
    return path ? `http://localhost:8082/${path}` : '';
  }

  openPopup(student: any) {
    this.selectedStudent = student;
    this.password = '';
    this.showPopup = true;
  }

  closePopup() {
    this.showPopup = false;
    this.selectedStudent = null;
    this.password = '';
    this.isLoading = false;
  }

  acceptStudent() {
    if (!this.selectedStudent || !this.password || this.isLoading) return;

    this.isLoading = true;

    this.inscriptionService
      .acceptStudent(this.selectedStudent.id, this.password)
      .subscribe({
        next: () => {
          this.closePopup();
          this.loadStudents();
        },
        error: (err) => {
          console.error(err);
          this.isLoading = false;
        }
      });
  }
}