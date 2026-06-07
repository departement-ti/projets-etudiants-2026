import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

@Component({
  selector: 'app-accueil',
  standalone: true,
  imports: [CommonModule ,RouterModule],
  templateUrl: './accueil.html',
  styleUrl: './accueil.scss',
})
export class Accueil {}
