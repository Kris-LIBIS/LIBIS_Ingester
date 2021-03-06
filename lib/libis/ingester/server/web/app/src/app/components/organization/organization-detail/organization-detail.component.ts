import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { Organization, User } from "../../../services/ingester-api/models";
import { Observable } from "rxjs/Observable";
import { DataModel } from "../../data.model";

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

  constructor() {
  }

  ngOnInit() {
  }

  onCancel() {
    this.cancelEvent.next();
  }

  onSave(data: DataModel) {
    console.log('OrgDetailComponent -> onSave');
    console.log(data);
    if (!!this.selectedOrg) {
      // this.selectedOrg.name = data.item('_name').control.value;
      // this.selectedOrg.code = data.item('_code').control.value;
      this.saveEvent.next(this.selectedOrg);
    }
  }

  // selectedIndex(user): number {
  //  return _.findIndex(this.selectedUsers, (u) => u.id === user.id);
  // }
  //
  // isSelected(user): boolean {
  //  return this.selectedIndex(user) > -1;
  // }
  //
  // toggleSelect(user): void {
  //  const index = this.selectedIndex(user);
  //  if (index > -1) {
  //    this.selectedUsers.splice(index, 1);
  //  } else {
  //    this.selectedUsers.push(user);
  //  }
  // }

}
