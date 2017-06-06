import { Injectable } from '@angular/core';
import { IngesterApiService } from "../../ingester-api/ingester-api.service";
import { Http } from "@angular/http";
import { Store } from "@ngrx/store";
import { AppState } from "../status/app-status";
import { User } from "../../ingester-api/models";
import { REFRESH_USERS } from "../reducers/user-list-reducer";

@Injectable()
export class UserServiceService extends IngesterApiService {

  constructor(private _http: Http, private _store: Store<AppState>) {
    super(_http);
  }

  load() {
    this.getObjectList(User)
      .map((users) => {type: REFRESH_USERS, payload: })
  }

}
