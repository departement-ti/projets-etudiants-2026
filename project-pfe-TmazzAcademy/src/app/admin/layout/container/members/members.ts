import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-members',
  standalone: true,
  imports: [CommonModule , RouterModule],
  templateUrl: './members.html',
  styleUrl: './members.scss',
})
export class Members {}
