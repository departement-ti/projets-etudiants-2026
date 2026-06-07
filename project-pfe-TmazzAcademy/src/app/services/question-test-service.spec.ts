import { TestBed } from '@angular/core/testing';

import { QuestionTestService } from './question-test-service';

describe('QuestionTestService', () => {
  let service: QuestionTestService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(QuestionTestService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
