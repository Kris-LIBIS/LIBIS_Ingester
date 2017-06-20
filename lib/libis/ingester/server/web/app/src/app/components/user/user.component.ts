import { Component, OnInit } from '@angular/core';
import * as _ from 'lodash';
import { Observable } from 'rxjs/Observable';
import { Store } from '@ngrx/store';
import { IAppState } from '../../services/datastore/app/state';
import { UserDeleteAction, UserLoadAction, UserSelectAction } from '../../services/datastore/users/actions';
import { IUserState } from '../../services/datastore/users/state';
import { IUser } from '../../services/datastore/users/model';
import { IOrganization } from "../../services/datastore/organizations/model";
import { OrganizationLoadAction } from "../../services/datastore/organizations/actions";

@Component({
  moduleId: module.id,
  selector: 'teneo-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss']
})
export class UserComponent implements OnInit {

  users: Observable<IUser[]>;
  selectedUser: Observable<IUser>;
  organizations: Observable<IOrganization[]>;

  constructor(protected _store: Store<IAppState>) { }

  ngOnInit() {
    this._store.dispatch(new UserLoadAction());
    this._store.dispatch(new OrganizationLoadAction());
    this.users = this._store.select('user').map((userState: IUserState) => userState.users);
    this.selectedUser = this._store.select('user').map((userState: IUserState) => userState.selectedUser);
    this.organizations = this._store.select('organization').map((org: IOrganization) => _.pick(org, ['id', 'name']))
  }

  editUser(user: IUser) {
    this._store.dispatch(new UserSelectAction(user));
  }

  deleteUser(user: IUser) {
    this._store.dispatch(new UserDeleteAction(user));
  }

}
