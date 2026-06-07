import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

import { Navbar } from './navbar/navbar';
import { Footer } from './footer/footer';
import { Container } from './container/container';

import { Chatbot } from '../../shared/chatbot/chatbot';

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [
    RouterModule,
    Navbar,
    Footer,
    Container,
    Chatbot
  ],
  templateUrl: './layout.html',
  styleUrl: './layout.scss',
})
export class Layout {}