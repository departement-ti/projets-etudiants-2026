import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { FavoriteCourseService } from '../../../../services/favorite-course-service';
import { CourseService } from '../../../../services/course-service';

@Component({
  selector: 'app-favorites',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './favorites.html',
  styleUrl: './favorites.scss',
})
export class Favorites implements OnInit {

  favorites: any[] = [];
  studentId = Number(localStorage.getItem('userId'));
  isLoading = true;

  constructor(
    private favoriteService: FavoriteCourseService,
    private courseService: CourseService
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);
    this.loadFavorites();
  }

  loadFavorites(): void {
    this.isLoading = true;

    this.favoriteService.getFavorites(this.studentId).subscribe({
      next: (data) => {
        this.favorites = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.log(err);
        this.isLoading = false;
      }
    });
  }

  getFileUrl(path?: string): string {
    return this.courseService.getFileUrl(path);
  }
}