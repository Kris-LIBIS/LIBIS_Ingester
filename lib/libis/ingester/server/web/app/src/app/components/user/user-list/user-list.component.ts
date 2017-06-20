import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import * as _ from 'lodash';
import { IUser, newUser } from '../../../services/datastore/users/model';
import { SelectItem } from "primeng/primeng";
import { IOrganization } from "../../../services/datastore/organizations/model";

@Component({
  selector: 'teneo-user-list',
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {

  @Input() users: IUser[];
  @Input() organizations: IOrganization[];
  @Output() editUserEvent: EventEmitter<IUser> = new EventEmitter();
  @Output() deleteUserEvent: EventEmitter<IUser> = new EventEmitter();

  constructor() {
  }

  ngOnInit() {
    // this.orgOptions = [];
    // this.organizations.forEach((org) => this.orgOptions.push({label: org.name, value:_.pick(org,['id', 'name'])}));
  }

  orgList(user: IUser): string {
    return user.organizations.map((org) => org.name).join(',');
  }

  orgOptions() : SelectItem[] {
    const options: SelectItem[] = [];
    this.organizations.forEach((org) => options.push({label: org.name, value:_.pick(org,['id', 'name'])}));
    return options;
  }

  addUser() {
    this.editUserEvent.next(newUser());
  }

}
