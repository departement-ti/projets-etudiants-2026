import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Sertif } from './sertif';

describe('Sertif', () => {
  let component: Sertif;
  let fixture: ComponentFixture<Sertif>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Sertif],
    }).compileComponents();

    fixture = TestBed.createComponent(Sertif);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
