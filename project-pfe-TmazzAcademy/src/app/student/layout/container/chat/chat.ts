import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ChatService } from '../../../../services/chat-service';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chat.html',
  styleUrl: './chat.scss'
})
export class Chat implements OnInit, OnDestroy {

  messages: any[] = [];

  message = '';
  selectedImage: File | null = null;

  showPoll = false;
  showEmojiPicker = false;

  pollQuestion = '';
  pollOptions: string[] = ['', ''];

  refreshInterval: any;

  userId = Number(localStorage.getItem('userId'));
  senderRole = localStorage.getItem('role') || 'USER';
  senderName = 'User';

  constructor(
    private chatService: ChatService,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    window.scrollTo(0, 0);

    this.loadCurrentUserName();
    this.loadMessages();

    this.refreshInterval = setInterval(() => {
      this.loadMessages();
    }, 3000);
  }

  ngOnDestroy(): void {
    clearInterval(this.refreshInterval);
  }

  loadCurrentUserName(): void {
    if (this.senderRole === 'ADMIN') {
      this.senderName = 'ADMIN';
      return;
    }

    if (this.senderRole === 'STUDENT') {
      this.http.get<any>(`http://localhost:8082/users/students/${this.userId}`)
        .subscribe({
          next: (data: any) => {
            this.senderName = `${data.name} ${data.lastname}`;
          },
          error: () => {
            this.senderName = 'Student';
          }
        });
    }

    if (this.senderRole === 'INSTRUCTOR') {
      this.http.get<any>(`http://localhost:8082/users/instructors/${this.userId}`)
        .subscribe({
          next: (data: any) => {
            this.senderName = `${data.name} ${data.lastname}`;
          },
          error: () => {
            this.senderName = 'Instructor';
          }
        });
    }
  }

  loadMessages(): void {
    this.chatService.getMessages().subscribe({
      next: (data: any[]) => {
        this.messages = data;
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  sendMessage(): void {
    if (!this.message.trim()) return;

    this.chatService.sendText({
      content: this.message,
      senderId: this.userId,
      senderName: this.senderName,
      senderRole: this.senderRole
    }).subscribe({
      next: () => {
        this.message = '';
        this.showEmojiPicker = false;
        this.loadMessages();
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    if (!input.files || input.files.length === 0) return;

    this.selectedImage = input.files[0];
    this.uploadImage();
    input.value = '';
  }

  uploadImage(): void {
    if (!this.selectedImage) return;

    const formData = new FormData();

    formData.append('image', this.selectedImage);
    formData.append('senderId', String(this.userId));
    formData.append('senderName', this.senderName);
    formData.append('senderRole', this.senderRole);

    this.chatService.sendImage(formData).subscribe({
      next: () => {
        this.selectedImage = null;
        this.loadMessages();
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  togglePoll(): void {
    this.showPoll = !this.showPoll;
    this.showEmojiPicker = false;
  }

  toggleEmojiPicker(): void {
    this.showEmojiPicker = !this.showEmojiPicker;
    this.showPoll = false;
  }

  addEmoji(emoji: string): void {
    this.message += emoji;
  }

  addOption(): void {
    this.pollOptions.push('');
  }

  createPoll(): void {
    const options = this.pollOptions.filter(o => o.trim());

    if (!this.pollQuestion.trim() || options.length < 2) return;

    this.chatService.createPoll({
      question: this.pollQuestion,
      options,
      senderId: this.userId,
      senderName: this.senderName,
      senderRole: this.senderRole
    }).subscribe({
      next: () => {
        this.pollQuestion = '';
        this.pollOptions = ['', ''];
        this.showPoll = false;
        this.loadMessages();
      },
      error: (err: any) => {
        console.error(err);
      }
    });
  }

  vote(messageId: number, optionId: number): void {
    this.chatService.vote(messageId, optionId, this.userId).subscribe({
      next: () => {
        this.loadMessages();
      },
      error: (err: any) => {
        alert(err?.error?.message || err?.error || 'You already voted');
      }
    });
  }

  getImageUrl(path: string): string {
    return this.chatService.getImageUrl(path);
  }
}