import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';

import { QuestionTestService } from '../../../../services/question-test-service';

@Component({
  selector: 'app-course-questions',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './course-questions.html',
  styleUrl: './course-questions.scss',
})
export class CourseQuestions implements OnInit {

  courseId!: number;
  questions: any[] = [];

  newQuestion = {
    question: '',
    optionA: '',
    optionB: '',
    optionC: '',
    optionD: '',
    correctAnswer: 'A'
  };

  successMessage = '';
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private questionService: QuestionTestService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.courseId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadQuestions();
  }

  loadQuestions(): void {
    this.questionService.getQuestions(this.courseId).subscribe({
      next: (data) => {
        this.questions = data;
      },
      error: () => {
        this.errorMessage = 'Error loading questions';
      }
    });
  }

  addQuestion(): void {
    this.successMessage = '';
    this.errorMessage = '';

    if (
      !this.newQuestion.question ||
      !this.newQuestion.optionA ||
      !this.newQuestion.optionB ||
      !this.newQuestion.optionC ||
      !this.newQuestion.optionD
    ) {
      this.errorMessage = 'Please fill all fields';
      return;
    }

    this.questionService.addQuestion(this.courseId, this.newQuestion).subscribe({
      next: () => {
        this.successMessage = 'Question added successfully';

        this.newQuestion = {
          question: '',
          optionA: '',
          optionB: '',
          optionC: '',
          optionD: '',
          correctAnswer: 'A'
        };

        this.loadQuestions();

        setTimeout(() => {
          this.successMessage = '';
        }, 2500);
      },
      error: () => {
        this.errorMessage = 'Error adding question';
      }
    });
  }

  deleteQuestion(id: number): void {
    if (!confirm('Are you sure you want to delete this question?')) return;

    this.questionService.deleteQuestion(id).subscribe({
      next: () => {
        this.loadQuestions();
      },
      error: () => {
        this.errorMessage = 'Error deleting question';
      }
    });
  }
}