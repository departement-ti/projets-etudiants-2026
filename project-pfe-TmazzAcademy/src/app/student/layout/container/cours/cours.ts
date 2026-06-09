import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CourseService } from '../../../../services/course-service';
import { Course } from '../../../../model/course.model';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-cours',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './cours.html',
  styleUrl: './cours.scss'
})
export class Cours implements OnInit {

  courses: Course[] = [];
  isLoading = false;
  errorMessage = '';

  constructor(
    private courseService: CourseService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    this.loadCourses();
  }

  loadCourses(): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.courseService.getAllCourses().subscribe({
      next: (data) => {
        console.log('COURSES DATA:', data);

        this.zone.run(() => {
          this.courses = data;
          this.isLoading = false;
          this.cdr.detectChanges();
        });
      },
      error: (err) => {
        console.error('COURSES ERROR:', err);

        this.zone.run(() => {
          this.errorMessage = 'Error loading courses';
          this.isLoading = false;
          this.cdr.detectChanges();
        });
      }
    });
  }

  getFileUrl(path?: string): string {
    return this.courseService.getFileUrl(path);
  }
}