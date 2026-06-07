import { CommonModule } from '@angular/common';
import { Component, HostListener, OnDestroy, OnInit } from '@angular/core';
import { Router, RouterLinkActive, RouterModule } from '@angular/router';
import { NotificationService } from '../../../services/notification-service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule, RouterLinkActive],
  templateUrl: './navbar.html',
  styleUrl: './navbar.scss',
})
export class Navbar implements OnInit, OnDestroy {

  isMenuOpen = false;
  isScrolled = false;

  notifications: any[] = [];
  showNotifications = false;
  interval: any;

  constructor(
    private router: Router,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadNotifications();

    this.interval = setInterval(() => {
      this.loadNotifications();
    }, 5000);
  }

  ngOnDestroy(): void {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  loadNotifications(): void {
    this.notificationService.getByRole('ADMIN').subscribe({
      next: (data) => {
        this.notifications = data;
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  toggleNotifications(): void {
    this.showNotifications = !this.showNotifications;
  }

  toggleMenu(): void {
    this.isMenuOpen = !this.isMenuOpen;
  }

  closeMenu(): void {
    this.isMenuOpen = false;
  }

  @HostListener('window:scroll')
  onScroll(): void {
    this.isScrolled = window.scrollY > 10;
  }

  logout(): void {
    localStorage.clear();
    this.isMenuOpen = false;
    this.router.navigate(['/Login']);
  }
}