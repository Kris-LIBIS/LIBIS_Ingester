import { Component, OnInit } from '@angular/core';
import { Observable } from "rxjs/Observable";
import { Organization, User } from "../../../services/ingester-api/models";
import { Store } from "@ngrx/store";
import { IAppState } from "../../../services/datastore/state/app-state";
import { DataModel, DataModelItem } from "../../data.model";

@Component({
  selector: 'teneo-user-list',
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {

  users$: Observable<User[]>;

  dataModel: DataModel = new DataModel([
    new DataModelItem('Name', '_name'),
    new DataModelItem('Role', '_role'),
    new DataModelItem('Organizations', 'organizations')
  ]);

  selectedObject: User = null;
  allRelated: Organization[] = [];


  constructor(private _store: Store<IAppState>) { }

  ngOnInit() {
    this.users$ = this._store.select('user.users');
  }

}
