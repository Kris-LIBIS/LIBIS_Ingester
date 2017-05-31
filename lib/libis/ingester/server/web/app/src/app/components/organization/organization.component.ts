import { Component, OnInit } from '@angular/core';
import { Organization, User } from "../../services/datastore/models";
import { IngesterApiService } from "../../services/datastore/ingester-api.service";
import { Observable } from "rxjs/Observable";
import { DataModel, DataModelControl, DataModelItem } from "../data.model";
import { Subject } from "rxjs/Subject";
import { AttributeMetadata } from "ng-jsonapi";

@Component({
  moduleId: module.id,
  selector: 'teneo-organization',
  templateUrl: './organization.component.html',
  styleUrls: ['./organization.component.scss']
})
export class OrganizationComponent implements OnInit {

  dataModel: DataModel = new DataModel([
    new DataModelItem('Name', '_name'),
    new DataModelItem('Code', '_code'),
    new DataModelItem('Producer', 'producerName'),
    new DataModelItem('Users', 'userList')
  ]);

  objects: Observable<Array<Organization>>;
  selectedObject = new Subject();
  objSelected: boolean = false;
  allRelated: User[] = [];

  constructor(protected api: IngesterApiService) {
  }

  ngOnInit() {
    this.objects = this.api.getObjectList(Organization);
    this.api.getObjectList(User).subscribe((users) => this.allRelated = users);
    this.selectedObject.subscribe((org) => this.objSelected = !!org);
  }

  deleteObject(object: Organization) {
    this.api.deleteObject(Organization, object).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  editObject(object: Organization) {
    this.selectedObject.next(object || new Organization(this.api));
  }

  saveObject(org: Organization) {
    console.log(org);
    this.api.saveObject(org[AttributeMetadata], org).subscribe((org) => this.ngOnInit());
    this.selectedObject.next(null);
  }

  cancelEdit() {
    this.selectedObject.next(null);
  }
}
