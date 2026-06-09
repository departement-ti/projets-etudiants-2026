import { Component, ViewChild, ElementRef, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { CourseService } from '../../../../services/course-service';

@Component({
  selector: 'app-cours',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './cours.html',
  styleUrl: './cours.scss'
})
export class Cours implements OnInit {

  @ViewChild('videoInput') videoInput!: ElementRef<HTMLInputElement>;
  @ViewChild('pdfInput') pdfInput!: ElementRef<HTMLInputElement>;

  titre = '';
  description = '';

  videoFile: File | null = null;
  pdfFile: File | null = null;

  courses: any[] = [];
  editingCourseId: number | null = null;

  commentsByCourse: { [courseId: number]: any[] } = {};
  openedCommentsCourseId: number | null = null;

  editCourse = {
    titre: '',
    description: ''
  };

  isLoading = false;
  successMessage = '';
  errorMessage = '';

  constructor(private courseService: CourseService) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadInstructorCourses();
  }

  loadInstructorCourses(): void {
    const instructorId = Number(localStorage.getItem('userId'));

    if (!instructorId) return;

    this.courseService.getCoursesByInstructor(instructorId).subscribe({
      next: (data) => {
        this.courses = data;
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  toggleComments(courseId: number): void {
    this.errorMessage = '';

    if (this.openedCommentsCourseId === courseId) {
      this.openedCommentsCourseId = null;
      return;
    }

    this.openedCommentsCourseId = courseId;

    if (this.commentsByCourse[courseId]) return;

    this.courseService.getCourseComments(courseId).subscribe({
      next: (data) => {
        this.commentsByCourse[courseId] = data;
      },
      error: (err) => {
        console.error(err);
        this.errorMessage = 'Error loading comments';
      }
    });
  }

  startEdit(course: any): void {
    this.editingCourseId = course.id;

    this.editCourse = {
      titre: course.titre,
      description: course.description
    };
  }

  cancelEdit(): void {
    this.editingCourseId = null;

    this.editCourse = {
      titre: '',
      description: ''
    };
  }

  saveEdit(id: number): void {
    this.courseService.updateCourse(id, this.editCourse).subscribe({
      next: () => {
        this.editingCourseId = null;
        this.successMessage = 'Course updated successfully';
        this.loadInstructorCourses();

        setTimeout(() => {
          this.successMessage = '';
        }, 2500);
      },
      error: (err) => {
        console.error(err);
        this.errorMessage = 'Error updating course';
      }
    });
  }

  deleteCourse(id: number): void {
    if (!confirm('Are you sure you want to delete this course?')) return;

    this.courseService.deleteCourse(id).subscribe({
      next: () => {
        this.successMessage = 'Course deleted successfully';
        this.loadInstructorCourses();

        setTimeout(() => {
          this.successMessage = '';
        }, 2500);
      },
      error: (err) => {
        console.error(err);
        this.errorMessage = 'Error deleting course';
      }
    });
  }

  onVideoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    this.videoFile =
      input.files && input.files.length > 0
        ? input.files[0]
        : null;

    this.successMessage = '';
    this.errorMessage = '';
  }

  onPdfSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    this.pdfFile =
      input.files && input.files.length > 0
        ? input.files[0]
        : null;

    this.successMessage = '';
    this.errorMessage = '';
  }

  resetForm(): void {
    this.titre = '';
    this.description = '';

    this.videoFile = null;
    this.pdfFile = null;

    this.isLoading = false;

    if (this.videoInput) {
      this.videoInput.nativeElement.value = '';
    }

    if (this.pdfInput) {
      this.pdfInput.nativeElement.value = '';
    }
  }

  submitCourse(): void {
    this.successMessage = '';
    this.errorMessage = '';

    if (this.isLoading) return;

    if (!this.titre.trim()) {
      this.errorMessage = 'Titre is required';
      return;
    }

    if (!this.description.trim()) {
      this.errorMessage = 'Description is required';
      return;
    }

    if (!this.videoFile) {
      this.errorMessage = 'Video is required';
      return;
    }

    if (!this.pdfFile) {
      this.errorMessage = 'PDF is required';
      return;
    }

    const instructorId = Number(localStorage.getItem('userId'));

    if (!instructorId) {
      this.errorMessage = 'Instructor ID not found. Please login again.';
      return;
    }

    this.isLoading = true;

    const formData = new FormData();

    formData.append('titre', this.titre);
    formData.append('description', this.description);
    formData.append('video', this.videoFile);
    formData.append('pdf', this.pdfFile);

    this.courseService.addCourse(instructorId, formData).subscribe({
      next: () => {
        this.resetForm();

        this.successMessage = 'Course added successfully';

        this.loadInstructorCourses();

        setTimeout(() => {
          this.successMessage = '';
        }, 3000);
      },
      error: (err) => {
        console.error('UPLOAD ERROR:', err);

        this.errorMessage = 'Error adding course';

        this.isLoading = false;
      }
    });
  }
}