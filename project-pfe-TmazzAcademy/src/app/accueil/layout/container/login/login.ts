import { Component } from '@angular/core';
import { Auth } from '../../../../services/auth';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class Login {

  email = '';
  password = '';
  errorMessage = '';

  showPassword = false;

  constructor(
    private auth: Auth,
    private router: Router
  ) {}

  togglePassword() {
    this.showPassword = !this.showPassword;
  }

  onLogin() {
    const data = {
      email: this.email,
      password: this.password
    };

    this.auth.login(data).subscribe({
      next: (res) => {

        this.auth.saveToken(res.token);
        this.auth.saveRole(res.role);

        localStorage.setItem('userId', res.userId);

        if (res.role === 'ADMIN') {
          this.router.navigate(['/admin']);
        }
        else if (res.role === 'INSTRUCTOR') {
          this.router.navigate(['/instructor']);
        }
        else {
          this.router.navigate(['/student']);
        }
      },

      error: () => {
        this.errorMessage =
          "Email ou mot de passe incorrect";
      }
    });
  }
}