import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { Organization, User } from "../../../datastore/models";
import { FormGroup } from "@angular/forms";
import { IngesterApiService } from "../../../datastore/ingester-api.service";
import { Router } from "@angular/router";
import { Observable } from "rxjs/Observable";
import * as _ from 'lodash';
import { DataModel } from "../../data.model";
import { Subject } from "rxjs/Subject";
import { AttributeMetadata } from "ng-jsonapi";

@Component({
  moduleId: module.id,
  selector: 'teneo-organization-detail',
  templateUrl: './organization-detail.component.html',
  styleUrls: ['./organization-detail.component.scss']
})
export class OrganizationDetailComponent implements OnInit {

  private id: string;
  @Input() organization: Observable<Organization>;
  @Input() allUsers: User[];
  @Output() cancelEvent = new EventEmitter();
  @Output() saveEvent = new EventEmitter();
  private modelData: DataModel;
  private selectedOrg: Organization = null;

  constructor(public api: IngesterApiService,
              private router: Router) {
  }

  protected addModelData(org: Organization) {
    if (!!org) {
      this.modelData.items.forEach((item) => {
        switch(item.key) {
        case '_name': {
            item.control.value = org.name;
            break;
          }
          case '_code': {
            item.control.value = org.code;
          }
        }
      });
    }
  }

  ngOnInit() {
    this.modelData = new DataModel();
    this.modelData.addItem('Name', '_name').setControl('', true).setInfo('textbox').setTextBox();
    this.modelData.addItem('Code', '_code').setControl('').setInfo('textbox').setTextBox();
    this.organization.subscribe((org) => {
      this.addModelData(org);
      this.selectedOrg = org;
    });
  }

  onCancel() {
    this.cancelEvent.next();
  }

  onSave(data: DataModel) {
    console.log('OrgDetailComponent -> onSave');
    console.log(data);
    if (!!this.selectedOrg) {
      this.selectedOrg.name = data.item('_name').control.value;
      this.selectedOrg.code = data.item('_code').control.value;
      this.saveEvent.next(this.selectedOrg);
    }
  }

  //selectedIndex(user): number {
  //  return _.findIndex(this.selectedUsers, (u) => u.id === user.id);
  //}
  //
  //isSelected(user): boolean {
  //  return this.selectedIndex(user) > -1;
  //}
  //
  //toggleSelect(user): void {
  //  const index = this.selectedIndex(user);
  //  if (index > -1) {
  //    this.selectedUsers.splice(index, 1);
  //  } else {
  //    this.selectedUsers.push(user);
  //  }
  //}

}
