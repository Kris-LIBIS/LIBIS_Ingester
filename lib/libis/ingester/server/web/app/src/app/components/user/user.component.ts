import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../datastore/ingester-api.service";
import { User } from "../../datastore/models";
import * as _ from 'lodash';

@Component({
  selector: 'teneo-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.css']
})
export class UserComponent implements OnInit {
  private users: User[] = [];
  private currentUser: User;

  constructor(private api: IngesterApiService) { }

  ngOnInit() {
    this.api.getUsers().subscribe((users) => this.users = users);
  }

  onSelect(id: string) {
    this.api.getUser(id).subscribe((user) => this.currentUser = user);
  }

  deleteUser(id: string) {
    this.api.deleteUser(id).subscribe((res) => {
      console.log(res);
      this.ngOnInit();
    });
  }

  orglist(orgs): string {
    return _.map(orgs, (org) => org.name).join(', ');
  }

}
