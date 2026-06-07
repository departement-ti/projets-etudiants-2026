import { ComponentFixture, TestBed } from '@angular/core/testing';

import { OurStudents } from './our-students';

describe('OurStudents', () => {
  let component: OurStudents;
  let fixture: ComponentFixture<OurStudents>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OurStudents],
    }).compileComponents();

    fixture = TestBed.createComponent(OurStudents);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
