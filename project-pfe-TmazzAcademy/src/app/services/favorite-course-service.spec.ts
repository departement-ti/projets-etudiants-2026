import { TestBed } from '@angular/core/testing';

import { FavoriteCourseService } from './favorite-course-service';

describe('FavoriteCourseService', () => {
  let service: FavoriteCourseService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(FavoriteCourseService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
