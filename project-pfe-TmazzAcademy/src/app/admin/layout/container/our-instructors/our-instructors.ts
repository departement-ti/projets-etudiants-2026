import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import { InstructorService } from '../../../../services/instructor-service';
import { ITblInstuctor } from '../../../../model/instructor.model';

@Component({
  selector: 'app-our-instructors',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './our-instructors.html',
  styleUrl: './our-instructors.scss'
})
export class OurInstructors implements OnInit {

  instructors: ITblInstuctor[] = [];

  constructor(
    private instructorService: InstructorService,
    private router: Router,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    this.loadInstructors();
  }

  loadInstructors() {
    this.instructorService.getAll().subscribe({
      next: (data) => {
        this.zone.run(() => {
          this.instructors = [...data];
          this.cdr.detectChanges();
        });
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  viewInstructor(id: number | undefined) {
    if (!id) return;
    this.router.navigate(['/admin/VeiwInstructor', id]);
  }

  deleteInstructor(id: number | undefined) {
    if (!id) return;

    if (confirm('Are you sure you want to delete this instructor?')) {
      this.instructorService.delete(id).subscribe({
        next: () => {
          this.loadInstructors();
        },
        error: (err) => {
          console.error(err);
        }
      });
    }
  }
}