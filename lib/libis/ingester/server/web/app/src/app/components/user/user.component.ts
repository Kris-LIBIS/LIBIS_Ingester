import { Component, OnInit } from '@angular/core';
import { Organization, User } from '../../services/ingester-api/models';
import { DataModel, DataModelItem } from '../data.model';
import { Observable } from 'rxjs/Observable';
import { Store } from '@ngrx/store';
import { IAppState } from '../../services/datastore/state/app-state';
import { UserLoadAction } from '../../services/datastore/users/actions';
import { IUserMap, IUserState } from '../../services/datastore/users/state';
import { IUser } from '../../services/datastore/users/model';

@Component({
  moduleId: module.id,
  selector: 'teneo-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss']
})
export class UserComponent implements OnInit {

  dataModel: DataModel = new DataModel([
    new DataModelItem('Name', '_name'),
    new DataModelItem('Role', '_role'),
    new DataModelItem('Organizations', 'organizations')
  ]);

  objects: Observable<IUser[]>;
  selectedObject: User = null;
  allRelated: Organization[] = [];

  constructor(protected store: Store<IAppState>) { }

  ngOnInit() {
    this.store.dispatch(new UserLoadAction());
    this.objects = this.store.select('user').map((userState: IUserState) => userState.ids.reduce((users: any[], id: string) => {
      const user = userState.users[id];
      users.push({
          id: user.id,
          name: user.name,
          role: user.role,
          organizations: user.organizations.map((org) => org.name).join(',')
        });
      return users;
    }, []));
    // this.api.getObjectList(Organization).subscribe((orgs) => this.allRelated = orgs);
    this.cancelEdit();
  }

  deleteObject(object: User) {
    // this.api.deleteObject(User, object).subscribe((res) => {
    //   console.log(res);
    //   this.ngOnInit();
    // });
  }

  editObject(object: User) {
    this.selectedObject = object;
  }

  saveObject(obj: User) {
    console.log(obj);
    // this.api.saveObject(obj[AttributeMetadata], obj).subscribe((org) => this.ngOnInit());
    this.cancelEdit();
  }

  cancelEdit() {
    // this.selectedObject = new User(this.api);
  }

}
