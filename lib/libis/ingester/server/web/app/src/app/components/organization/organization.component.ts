import { Component, OnInit } from '@angular/core';
import { Organization, User } from "../../datastore/models";
import { IngesterApiService } from "../../datastore/ingester-api.service";
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
  selectedOrg = new Subject();
  orgSelected: boolean = false;
  allUsers: User[] = [];

  constructor(protected api: IngesterApiService) {
  }

  ngOnInit() {
    this.objects = this.api.getObjectList(Organization);
    this.api.getObjectList(User).subscribe((users) => this.allUsers = users);
    this.selectedOrg.subscribe((org) => this.orgSelected = !!org);
  }

  deleteObject(object: Organization) {
    this.api.deleteObject(Organization, object).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  editObject(object: Organization) {
    this.selectedOrg.next(object || new Organization(this.api));
  }

  saveObject(org: Organization) {
    console.log(org);
    this.api.saveObject(org[AttributeMetadata], org).subscribe((org) => this.ngOnInit());
    this.selectedOrg.next(null);
  }

  cancelEdit() {
    this.selectedOrg.next(null);
  }
}
