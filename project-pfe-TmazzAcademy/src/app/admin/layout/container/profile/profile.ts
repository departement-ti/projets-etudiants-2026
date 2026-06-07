import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './profile.html',
  styleUrl: './profile.scss',
})
export class Profile {

  admin = {
    name: 'Admin',
    lastname: 'Tmazz Academy',
    email: 'admin@tmazzacademy.com',
    role: 'ADMIN'
  };

  get fullName(): string {
    return `${this.admin.name} ${this.admin.lastname}`;
  }
}