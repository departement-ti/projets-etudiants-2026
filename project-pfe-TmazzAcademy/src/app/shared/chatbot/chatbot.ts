import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { CourseService } from '../../services/course-service';

@Component({
  selector: 'app-chatbot',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chatbot.html',
  styleUrl: './chatbot.scss'
})
export class Chatbot implements OnInit {

  isOpen = false;

  message = '';

  role = localStorage.getItem('role') || 'STUDENT';

  courses: any[] = [];

  messages: any[] = [
    {
      from: 'bot',
      text: 'Hi 👋 I am your TMazz assistant. How can I help you?'
    }
  ];

  constructor(
    private courseService: CourseService
  ) {}

  ngOnInit(): void {

    this.courseService.getAllCourses().subscribe({

      next: (data: any) => {

        
        this.courses = (data as any[]).filter(course =>

          (course as any).active === true ||
          (course as any).active === 1
        );
      },

      error: (err) => {
        console.error(err);
      }
    });
  }

  toggleChat(): void {
    this.isOpen = !this.isOpen;
  }

  sendMessage(): void {

    const text = this.message.trim();

    if (!text) return;

    this.messages.push({
      from: 'user',
      text
    });

    this.message = '';

    this.localReply(text);
  }

  

  cleanWords(text: string): string[] {

    const stopWords = [
      'and',
      'the',
      'for',
      'with',
      'want',
      'learn',
      'course',
      'courses',
      'best',
      'good',
      'about',
      'please',
      'help',
      'i',
      'to'
    ];

    return text
      .toLowerCase()
      .split(/\s+/)
      .map(w => w.replace(/[^a-z0-9]/g, ''))
      .filter(w =>
        w.length > 2 &&
        !stopWords.includes(w)
      );
  }

  

  localReply(text: string): void {

    const lower = text.toLowerCase();

    if (this.role === 'STUDENT') {

      this.studentReply(lower);

    } else if (this.role === 'INSTRUCTOR') {

      this.instructorReply(lower);

    } else {

      this.messages.push({
        from: 'bot',
        text:
          'I can help students choose courses and instructors create courses.'
      });
    }
  }

  

  studentReply(text: string): void {

    const words = this.cleanWords(text);

    if (words.length === 0) {

      this.messages.push({
        from: 'bot',
        text:
          'Tell me a specific topic like Angular, Java, Spring Boot, Node.js, or English.'
      });

      return;
    }

    const matchedCourses = this.courses.filter(course => {

      
      if (
        (course as any).active === false ||
        (course as any).active === 0
      ) {
        return false;
      }

      const title =
        course.titre?.toLowerCase() || '';

      const description =
        course.description?.toLowerCase() || '';

      return words.some(word =>

        title.includes(word) ||
        description.includes(word)
      );
    });

    

    if (matchedCourses.length > 0) {

      const bestCourses = matchedCourses

        .sort((a, b) =>
          (b.rating || 0) - (a.rating || 0)
        )

        .slice(0, 3)

        .map(c =>

`📘 ${c.titre}

⭐ ${c.rating || 0}/5

${c.description}`
        )

        .join('\n\n');

      this.messages.push({
        from: 'bot',
        text:
`I recommend these courses:

${bestCourses}`
      });

      return;
    }

    

    if (
      text.includes('certificate') ||
      text.includes('sertif')
    ) {

      this.messages.push({
        from: 'bot',
        text:
'To get a certificate, you must pass the test with at least 10/20.'
      });

      return;
    }

    

    if (
      text.includes('test') ||
      text.includes('quiz') ||
      text.includes('exam')
    ) {

      this.messages.push({
        from: 'bot',
        text:
'Open the course and click Start Test. If your score is 10/20 or more, you pass.'
      });

      return;
    }

    

    const availableCourses = this.courses

      .filter(course =>

        (course as any).active === true ||
        (course as any).active === 1
      )

      .map(course =>

        `📘 ${course.titre}`
      )

      .join('\n');

    this.messages.push({
      from: 'bot',
      text:
`Sorry 😅

I could not find an active course related to:
"${text}"

Available active courses are:

${availableCourses || 'No active courses available right now.'}`
    });
  }

  

  instructorReply(text: string): void {

    
    if (
      text.includes('description')
    ) {

      this.messages.push({
        from: 'bot',
        text:
'A good course description explains what students will learn and the final project result.'
      });

      return;
    }

    if (
      text.includes('test') ||
      text.includes('quiz') ||
      text.includes('question')
    ) {

      this.messages.push({
        from: 'bot',
        text:
'Good quizzes should contain clear questions, 4 answers, and one correct answer.'
      });

      return;
    }


    if (
      text.includes('course')
    ) {

      this.messages.push({
        from: 'bot',
        text:
'A strong course needs a clear title, organized videos, PDFs, and a final quiz.'
      });

      return;
    }

    
    this.messages.push({
      from: 'bot',
      text:
`I can help instructors with:

✅ Course descriptions
✅ Quiz creation
✅ Better course structure
✅ Teaching advice`
    });
  }
}
