import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';

import { CourseService } from '../../../../services/course-service';
import { FavoriteCourseService } from '../../../../services/favorite-course-service';

@Component({
  selector: 'app-course-details',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './course-details.html',
  styleUrl: './course-details.scss'
})
export class CourseDetails implements OnInit, OnDestroy {

  courseId!: number;
  studentId = Number(localStorage.getItem('userId'));

  course: any = null;
  questions: any[] = [];
  comments: any[] = [];

  answers: any = {};
  testResult: any = null;

  showTest = false;
  testBlocked = false;
  testBlockMessage = '';
  attemptsLeft = -1;
  countdownText = '';

  private countdownInterval: any;
  private secondsLeft = 0;

  isFavorite = false;

  newComment = {
    comment: '',
    stars: 5
  };

  constructor(
    private route: ActivatedRoute,
    private http: HttpClient,
    private courseService: CourseService,
    private favoriteService: FavoriteCourseService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);

    this.courseId = Number(this.route.snapshot.paramMap.get('id'));

    this.loadCourse();
    this.loadQuestions();
    this.loadComments();
    this.checkFavorite();
    this.loadTestStatus();
  }

  ngOnDestroy(): void {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }
  }

  loadCourse(): void {
    this.courseService.getCourseById(this.courseId).subscribe({
      next: (data: any) => {
        this.course = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  loadQuestions(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/questions/course/${this.courseId}`
    ).subscribe({
      next: (data: any[]) => {
        this.questions = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  loadComments(): void {
    this.http.get<any[]>(
      `http://localhost:8082/api/comments/course/${this.courseId}`
    ).subscribe({
      next: (data: any[]) => {
        this.comments = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  loadTestStatus(): void {
    this.http.get<any>(
      `http://localhost:8082/api/tests/student/${this.studentId}/course/${this.courseId}/status`
    ).subscribe({
      next: (data: any) => {
        this.testBlocked = !data.canStart;
        this.testBlockMessage = data.message || '';
        this.attemptsLeft = data.attemptsLeft ?? -1;

        this.secondsLeft =
          data.secondsLeft ||
          data.remainingSeconds ||
          data.countdownSeconds ||
          0;

        if (this.secondsLeft > 0) {
          this.startCountdown(this.secondsLeft);
        } else {
          this.countdownText = '';
        }
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  startCountdown(seconds: number): void {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }

    this.updateCountdownText(seconds);

    this.countdownInterval = setInterval(() => {
      seconds--;

      if (seconds <= 0) {
        clearInterval(this.countdownInterval);
        this.countdownText = '';
        this.loadTestStatus();
        return;
      }

      this.updateCountdownText(seconds);
    }, 1000);
  }

  updateCountdownText(seconds: number): void {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    this.countdownText = `${hours}h ${minutes}m ${secs}s`;
  }

  startTest(): void {
    if (this.testBlocked) {
      alert(this.testBlockMessage || 'Test is locked');
      return;
    }

    this.showTest = true;
    this.testResult = null;
    this.answers = {};
  }

  submitTest(): void {
    const payload = {
      answers: this.answers
    };

    this.http.post<any>(
      `http://localhost:8082/api/tests/student/${this.studentId}/course/${this.courseId}`,
      payload
    ).subscribe({
      next: (data: any) => {
        this.testResult = data;
        this.showTest = false;
        this.loadTestStatus();
      },
      error: (err: any) => {
        console.error(err);

        const msg =
          err?.error?.message ||
          err?.error?.error ||
          err?.error ||
          'Error submitting test';

        alert(msg);
        this.loadTestStatus();
      }
    });
  }

  addComment(): void {
    if (!this.newComment.comment.trim()) return;

    this.http.post<any>(
      `http://localhost:8082/api/comments/student/${this.studentId}/course/${this.courseId}`,
      this.newComment
    ).subscribe({
      next: () => {
        this.newComment = {
          comment: '',
          stars: 5
        };

        this.loadComments();
        this.loadCourse();
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  addEmoji(emoji: string): void {
    this.newComment.comment += emoji;
  }

  checkFavorite(): void {
    this.favoriteService.isFavorite(this.studentId, this.courseId).subscribe({
      next: (data: boolean) => {
        this.isFavorite = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  toggleFavorite(): void {
    if (this.isFavorite) {
      this.favoriteService.removeFavorite(this.studentId, this.courseId).subscribe({
        next: () => {
          this.isFavorite = false;
        },
        error: (err: any) => {
          console.error(err);
        }
      });
    } else {
      this.favoriteService.addFavorite(this.studentId, this.courseId).subscribe({
        next: () => {
          this.isFavorite = true;
        },
        error: (err: any) => {
          console.error(err);
        }
      });
    }
  }

  getFileUrl(path?: string): string {
    return this.courseService.getFileUrl(path);
  }
}