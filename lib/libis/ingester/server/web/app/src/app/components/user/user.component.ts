import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../services/datastore/ingester-api.service";
import { Organization, User } from "../../services/datastore/models";
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
  selectedObject = new Subject();
  objSelected: boolean = false;
  allRelated: Organization[] = [];

  constructor(protected api: IngesterApiService) { }

  ngOnInit() {
    this.objects = this.api.getObjectList(User);
    this.api.getObjectList(Organization).subscribe((orgs) => this.allRelated = orgs);
    this.selectedObject.subscribe((user) => this.objSelected = !!user);
  }

  deleteObject(object: User) {
    this.api.deleteObject(User, object).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  editObject(object: User) {
    this.selectedObject.next(object || new User(this.api));
  }

  saveObject(obj: User) {
    console.log(obj);
    this.api.saveObject(obj[AttributeMetadata], obj).subscribe((org) => this.ngOnInit());
    this.selectedObject.next(null);
  }

  cancelEdit() {
    this.selectedObject.next(null);
  }

}
