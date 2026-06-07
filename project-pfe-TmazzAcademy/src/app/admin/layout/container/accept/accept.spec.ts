import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Accept } from './accept';

describe('Accept', () => {
  let component: Accept;
  let fixture: ComponentFixture<Accept>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Accept],
    }).compileComponents();

    fixture = TestBed.createComponent(Accept);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
