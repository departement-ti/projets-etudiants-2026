import { ComponentFixture, TestBed } from '@angular/core/testing';

import { OurInstructors } from './our-instructors';

describe('OurInstructors', () => {
  let component: OurInstructors;
  let fixture: ComponentFixture<OurInstructors>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OurInstructors],
    }).compileComponents();

    fixture = TestBed.createComponent(OurInstructors);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
