import { TestBed } from '@angular/core/testing';

import { CourseCommentService } from './course-comment-service';

describe('CourseCommentService', () => {
  let service: CourseCommentService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(CourseCommentService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
