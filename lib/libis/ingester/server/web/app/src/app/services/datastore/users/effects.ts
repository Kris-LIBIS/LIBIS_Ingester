import { Injectable } from "@angular/core";
import { Actions, Effect} from "@ngrx/effects";
import { Observable } from "rxjs/Observable";
import { Action } from "@ngrx/store";

import 'rxjs/add/operator/switchMap';
import 'rxjs/add/operator/skip';
import 'rxjs/add/operator/takeUntil';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/catch';
import { of } from 'rxjs/observable/of';

import * as user from './actions';
import { IngesterApiService } from "../../ingester-api/ingester-api.service";
import { User } from "../../ingester-api/models";


@Injectable()
export class UserEffects {

  constructor(private action$: Actions, private api: IngesterApiService) {
  }

  @Effect()
  load$: Observable<Action> = this.action$.ofType(user.LOAD).switchMap(() => {
    const nextLoad$ = this.action$.ofType(user.LOAD).skip(1);
    return this.api.getObjectList(User)
      .takeUntil(nextLoad$)
      .map((users) => new user.LoadSuccessAction(users))
      .catch(() => of(new user.LoadFailAction([])));
  });

}
