import { Component, EventEmitter, Output } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Auth } from '../../../../services/auth';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-instructor-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './instructor-form-component.html'
})
export class InstructorFormComponent {

  @Output() close = new EventEmitter<void>();

  form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private auth: Auth
  ) {
    this.form = this.fb.group({
      name: ['', Validators.required],
      lastname: ['', Validators.required],
      email: ['', Validators.required],
      password: ['', Validators.required],
      tel: ['', Validators.required],
      speciality: ['', Validators.required],
      role: ['INSTRUCTOR']
    });
  }

  submit() {
    if (this.form.valid) {
      this.auth.register(this.form.value).subscribe({
        next: () => {
          this.close.emit(); // close popup
        }
      });
    }
  }

  cancel() {
    this.close.emit();
  }
}