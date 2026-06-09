import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Inscript } from './inscript';

describe('Inscript', () => {
  let component: Inscript;
  let fixture: ComponentFixture<Inscript>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Inscript],
    }).compileComponents();

    fixture = TestBed.createComponent(Inscript);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
