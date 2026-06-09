import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { CourseService } from '../../../../services/course-service';
import { QuestionTestService } from '../../../../services/question-test-service';

@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './courses.html',
  styleUrl: './courses.scss'
})
export class Courses implements OnInit {
  courses: any[] = [];
  questions: any[] = [];
  selectedCourseId: number | null = null;
  editingCourseId: number | null = null;

  editCourse = { titre: '', description: '' };

  successMessage = '';
  errorMessage = '';

  constructor(
    private courseService: CourseService,
    private questionService: QuestionTestService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadCourses();
  }

  loadCourses(): void {
    this.courseService.getAllCourses().subscribe({
      next: (data: any[]) => this.courses = data,
      error: () => this.errorMessage = 'Error loading courses'
    });
  }

  viewQuestions(courseId: number): void {
    this.selectedCourseId = courseId;
    this.questions = [];

    this.questionService.getQuestions(courseId).subscribe({
      next: (data: any[]) => this.questions = data,
      error: () => this.errorMessage = 'Error loading questions'
    });
  }

  closeQuestions(): void {
    this.selectedCourseId = null;
    this.questions = [];
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
    this.editCourse = { titre: '', description: '' };
  }

  saveEdit(id: number): void {
    this.courseService.updateCourse(id, this.editCourse).subscribe({
      next: () => {
        this.successMessage = 'Course updated successfully';
        this.errorMessage = '';
        this.editingCourseId = null;
        this.loadCourses();
        setTimeout(() => this.successMessage = '', 2500);
      },
      error: () => this.errorMessage = 'Error updating course'
    });
  }

  deleteCourse(id: number): void {
    if (!confirm('Are you sure you want to delete this course?')) return;

    this.courseService.deleteCourse(id).subscribe({
      next: () => {
        this.successMessage = 'Course deleted successfully';
        this.errorMessage = '';
        this.loadCourses();
        this.closeQuestions();
        setTimeout(() => this.successMessage = '', 2500);
      },
      error: () => this.errorMessage = 'Error deleting course'
    });
  }
}