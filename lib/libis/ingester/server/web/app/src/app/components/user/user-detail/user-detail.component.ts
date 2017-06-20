import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { IUser } from "../../../services/datastore/users/model";
import { SelectItem } from "primeng/primeng";

@Component({
  moduleId: module.id,
  selector: 'teneo-user-detail',
  templateUrl: './user-detail.component.html',
  styleUrls: ['./user-detail.component.scss']
})
export class UserDetailComponent implements OnInit {

  @Input() user: IUser;
  @Input() allRelated: any[];
  @Output() cancelEvent = new EventEmitter();
  @Output() saveEvent = new EventEmitter();

  roles: SelectItem[];

  constructor() {
    this.roles = [];
    this.roles.push({label: 'Submitter', value: 'submitter'});
    this.roles.push({label: 'Administrator', value: 'admin'})
  }

  ngOnInit() {
  }

  invalid(): boolean {
    return !this.user.name;
  }

  onCancel() {
    this.cancelEvent.next();
  }

  onSave(user: IUser) {
    console.log('UserDetailComponent -> onSave');
    console.log(user);
    this.saveEvent.next(user);
  }

  submitForm(): boolean {
    this.onSave(this.user);
    return false;
  }

}
