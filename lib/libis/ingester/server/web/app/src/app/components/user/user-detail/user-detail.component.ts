import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { IUser } from '../../../services/datastore/users/model';

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

  constructor() {
  }

  ngOnInit() {
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
