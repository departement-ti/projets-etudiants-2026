import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CourseQuestions } from './course-questions';

describe('CourseQuestions', () => {
  let component: CourseQuestions;
  let fixture: ComponentFixture<CourseQuestions>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CourseQuestions],
    }).compileComponents();

    fixture = TestBed.createComponent(CourseQuestions);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
