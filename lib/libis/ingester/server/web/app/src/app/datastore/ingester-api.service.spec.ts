import { TestBed, inject } from '@angular/core/testing';

import { IngesterApiService } from './ingester-api.service';

describe('IngesterApiService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [IngesterApiService]
    });
  });

  it('should ...', inject([IngesterApiService], (service: IngesterApiService) => {
    expect(service).toBeTruthy();
  }));
});
