import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../services/ingester-api/ingester-api.service";
import { Organization, User } from "../../services/ingester-api/models";
import * as _ from 'lodash';
import { DataModel, DataModelItem } from "../data.model";
import { Observable } from "rxjs/Observable";
import { Subject } from "rxjs/Subject";
import { AttributeMetadata } from "ng-jsonapi";

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

  objects: Observable<Array<User>>;
  selectedObject: User = null;
  allRelated: Organization[] = [];

  constructor(protected api: IngesterApiService) { }

  ngOnInit() {
    this.objects = this.api.getObjectList(User);
    this.api.getObjectList(Organization).subscribe((orgs) => this.allRelated = orgs);
    this.cancelEdit();
  }

  deleteObject(object: User) {
    this.api.deleteObject(User, object).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  editObject(object: User) {
    this.selectedObject = object;
  }

  saveObject(obj: User) {
    console.log(obj);
    this.api.saveObject(obj[AttributeMetadata], obj).subscribe((org) => this.ngOnInit());
    this.cancelEdit();
  }

  cancelEdit() {
    this.selectedObject = new User(this.api);
  }

}
