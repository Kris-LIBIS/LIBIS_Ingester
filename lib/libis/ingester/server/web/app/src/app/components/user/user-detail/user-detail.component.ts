import { Component, OnInit } from '@angular/core';
import { User } from "../../../datastore/models";
import { IngesterApiService } from "../../../datastore/ingester-api.service";
import { ActivatedRoute } from "@angular/router";
import "rxjs/add/operator/switchMap";
import "rxjs/add/operator/do";
import { Observable } from "rxjs/Observable";

@Component({
  selector: 'teneo-user-detail',
  templateUrl: './user-detail.component.html',
  styleUrls: ['./user-detail.component.css']
})
export class UserDetailComponent implements OnInit {

  private user: User;

  constructor(private api: IngesterApiService, private route: ActivatedRoute) { }

  ngOnInit() {
    const user_id = this.route.params.map((params) => params['id']);
    user_id.subscribe((id) => this.api.getUser(id).subscribe((user) => this.user = user));
  }

  onSubmit(data: any) {
    for (const key in data) {
      this.user[key] = data[key];
    }
    this.api.saveRecord(this.user);
  }

}
