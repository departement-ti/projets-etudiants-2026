import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-accept',
  standalone: true,
  imports: [CommonModule , RouterModule],
  templateUrl: './accept.html',
  styleUrl: './accept.scss',
})
export class Accept {}
