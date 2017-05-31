import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { Organization, User } from "../../../services/datastore/models";
import { IngesterApiService } from "../../../services/datastore/ingester-api.service";
import { Router } from "@angular/router";
import { Observable } from "rxjs/Observable";
import { DataModel } from "../../data.model";

@Component({
  moduleId: module.id,
  selector: 'teneo-user-detail',
  templateUrl: './user-detail.component.html',
  styleUrls: ['./user-detail.component.scss']
})
export class UserDetailComponent implements OnInit {

  private id: string;
  @Input() object: Observable<User>;
  @Input() allRelated: Organization[];
  @Output() cancelEvent = new EventEmitter();
  @Output() saveEvent = new EventEmitter();
  private modelData: DataModel;
  private selectedObject: User = null;

  constructor() {
  }

  protected addModelData(obj: User) {
    if (!!obj) {
      this.modelData.items.forEach((item) => {
        switch(item.key) {
          case '_name': {
            item.control.value = obj.name;
            break;
          }
          case '_role': {
            item.control.value = obj.role;
          }
        }
      });
    }
  }

  ngOnInit() {
    this.modelData = new DataModel();
    this.modelData.addItem('Name', '_name').setControl('', true).setInfo('textbox').setTextBox();
    this.modelData.addItem('Role', '_role').setControl('').setInfo('textbox').setTextBox();
    this.object.subscribe((org) => {
      this.addModelData(org);
      this.selectedObject = org;
    });
  }

  onCancel() {
    this.cancelEvent.next();
  }

  onSave(data: DataModel) {
    console.log('OrgDetailComponent -> onSave');
    console.log(data);
    if (!!this.selectedObject) {
      this.selectedObject.name = data.item('_name').control.value;
      this.selectedObject.role = data.item('_role').control.value;
      this.saveEvent.next(this.selectedObject);
    }
  }

}
