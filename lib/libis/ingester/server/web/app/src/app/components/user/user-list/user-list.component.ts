import { Component, EventEmitter, Input, OnInit } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import { Organization, User } from '../../../services/ingester-api/models';
import { DataModel, DataModelItem } from '../../data.model';
import { IUser } from '../../../services/datastore/users/model';
import { Subject } from 'rxjs/Subject';
import { Store } from "@ngrx/store";
import { IAppState } from "../../../services/datastore/state/app-state";
import { IUserState } from "../../../services/datastore/users/state";
import { UserSelectAction } from "../../../services/datastore/users/actions";

@Component({
  selector: 'teneo-user-list',
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {

  @Input() users$: Observable<IUser[]>;
  selectedUser: Observable<IUser>;

  dataModel: DataModel = new DataModel([
    new DataModelItem('Name', 'name'),
    new DataModelItem('Role', 'role'),
    new DataModelItem('Organizations', 'organizations')
  ]);

  allRelated: Organization[] = [];


  constructor(private _store: Store<IAppState>) { }

  ngOnInit() {
    this.selectedUser = this._store.select('user').map((userState: IUserState) => userState.selectedUser);
  }

  editObject(user: IUser) {
      this._store.dispatch(new UserSelectAction(user));
  }
}
