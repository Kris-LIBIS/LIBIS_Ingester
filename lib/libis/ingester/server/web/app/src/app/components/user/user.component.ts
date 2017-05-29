import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../services/datastore/ingester-api.service";
import { User } from "../../services/datastore/models";
import * as _ from 'lodash';

@Component({
  moduleId: module.id,
  selector: 'teneo-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss']
})
export class UserComponent implements OnInit {
  private users: User[] = [];

  constructor(private api: IngesterApiService) { }

  ngOnInit() {
    this.api.getObjectList(User).subscribe((users) => this.users = users);
  }

  deleteUser(user: User) {
    this.api.deleteObject(User, user).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  orglist(orgs): string {
    return _.map(orgs, (org) => org.name).join(', ');
  }

}
