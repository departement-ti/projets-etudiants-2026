import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Inscription } from '../../../../services/inscription';

@Component({
  selector: 'app-instructors',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './instructors.html',
  styleUrl: './instructors.scss'
})
export class Instructors implements OnInit {

  instructors: any[] = [];

  selectedInstructor: any = null;
  showPopup = false;
  password = '';
  isLoading = false;

  constructor(
    private inscriptionService: Inscription,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    console.log('Instructors component loaded');
    this.loadInstructors();
  }

  loadInstructors() {
    this.inscriptionService.getInstructorInscriptions().subscribe({
      next: (data) => {
        console.log('INSTRUCTORS DATA:', data);

        this.zone.run(() => {
          this.instructors = [...data];
          this.cdr.detectChanges();
        });
      },
      error: (err) => {
        console.error('ERROR GET INSTRUCTORS:', err);
      }
    });
  }

  openPopup(instructor: any) {
    this.selectedInstructor = instructor;
    this.password = '';
    this.showPopup = true;
  }

  closePopup() {
    this.showPopup = false;
    this.selectedInstructor = null;
    this.password = '';
    this.isLoading = false;
  }

  acceptInstructor() {
    if (!this.selectedInstructor || !this.password || this.isLoading) return;

    this.isLoading = true;

    this.inscriptionService
      .acceptInstructor(this.selectedInstructor.id, this.password)
      .subscribe({
        next: () => {
          this.closePopup();
          this.loadInstructors();
        },
        error: (err) => {
          console.error(err);
          this.isLoading = false;
        }
      });
  }
}