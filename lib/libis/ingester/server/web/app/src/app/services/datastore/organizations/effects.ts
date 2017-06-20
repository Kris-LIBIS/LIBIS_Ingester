import { Injectable } from '@angular/core';
import { Actions, Effect} from '@ngrx/effects';
import { Observable } from 'rxjs/Observable';
import { Action } from '@ngrx/store';

import 'rxjs/add/operator/switchMap';
import 'rxjs/add/operator/skip';
import 'rxjs/add/operator/takeUntil';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/catch';
import { of } from 'rxjs/observable/of';

import { IngesterApiService } from '../../ingester-api/ingester-api.service';
import { Organization } from '../../ingester-api/models';
import { ORGANIZATION_LOAD, OrganizationLoadFailAction, OrganizationLoadSuccessAction } from "./actions";


@Injectable()
export class OrganizationEffects {

  constructor(private action$: Actions, private api: IngesterApiService) {
  }

  @Effect()
  load$: Observable<Action> = this.action$.ofType(ORGANIZATION_LOAD).switchMap(() => {
    const nextLoad$ = this.action$.ofType(ORGANIZATION_LOAD).skip(1);
    const org$: Observable<Organization[]> = this.api.getObjectList(Organization);
    // return users$.takeUntil(nextLoad$)
    return org$
      .map((orgs) => new OrganizationLoadSuccessAction(orgs))
      .catch(() => of(new OrganizationLoadFailAction([])));
  });

}
