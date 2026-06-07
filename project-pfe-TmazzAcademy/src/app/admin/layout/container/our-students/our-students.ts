import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, NgZone, OnInit } from '@angular/core';
import { ITblStudent } from '../../../../model/student.model';
import { StudentService } from '../../../../services/student-service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-our-students',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './our-students.html',
  styleUrl: './our-students.scss',
})
export class OurStudents implements OnInit {

  students: ITblStudent[] = [];

  constructor(
    private studentService: StudentService,
    private router: Router,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    this.loadStudents();
  }

  loadStudents() {
    this.studentService.getAll().subscribe({
      next: (data) => {
        this.zone.run(() => {
          this.students = [...data];
          this.cdr.detectChanges();
        });
      },
      error: (err) => {
        console.error(err);
      }
    });
  }

  viewStudent(id: number | undefined) {
    if (!id) return;
    this.router.navigate(['/admin/VeiwStudents', id]);
  }

  deleteStudent(id: number | undefined) {
    if (!id) return;

    if (confirm('Are you sure you want to delete this student?')) {
      this.studentService.delete(id).subscribe({
        next: () => {
          this.loadStudents();
        },
        error: (err) => {
          console.error(err);
        }
      });
    }
  }
}