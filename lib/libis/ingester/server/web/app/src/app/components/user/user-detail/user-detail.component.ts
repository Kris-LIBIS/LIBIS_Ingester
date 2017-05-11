import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../../datastore/ingester-api.service";
import { ActivatedRoute, Params, Router } from "@angular/router";
import "rxjs/add/operator/switchMap";
import "rxjs/add/operator/do";
import "rxjs/add/operator/toPromise";
import { FormBuilder, FormGroup, Validators } from "@angular/forms";
import { AttributeMetadata } from "ng-jsonapi";
import { Organization, User } from "../../../datastore/models";

@Component({
  selector: 'teneo-user-detail',
  templateUrl: './user-detail.component.html',
  styleUrls: ['./user-detail.component.css']
})
export class UserDetailComponent implements OnInit {

  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    role: ['', Validators.required]
  });
  selectedOrgs: Organization[] = [];
  allOrgs: Organization[] = [];

  private id: string;

  constructor(public api: IngesterApiService,
              private router: Router,
              private route: ActivatedRoute,
              public fb: FormBuilder) {
  }

  ngOnInit() {
    this.api.getOrganizations()
      .subscribe((orgs) => orgs.forEach((org) => this.allOrgs.push(org)));
    this.route.params
      .map((params: Params) => params['id'])
      .switchMap((id: string) => {
        this.id = id;
        return this.api.getUser(id);
      })
      .do((user) => {
        this.form.controls['name'].patchValue(user.name);
        this.form.controls['role'].patchValue(user.role);
      })
      .switchMap((user) => this.api.getUserOrgs(user.links['organizations'].href))
      .subscribe((orgs: Organization[]) => {
        orgs.forEach((org) => {
          this.selectedOrgs.push(org);
        });
      });
  }

  onSubmit(form: FormGroup) {
    console.log(form);
    if (this.id === 'new') {
      const user = new User(this.api);
      user.name = form.getRawValue().name;
      user.role = form.getRawValue().role;
      this.api.saveUser(user[AttributeMetadata], user).subscribe((user) => this.router.navigate(['/users']));
    } else {
      this.api.getUser(this.id)
        .switchMap((user) => {
          user.name = form.getRawValue().name;
          user.role = form.getRawValue().role;
          return this.api.saveUser(user[AttributeMetadata], user);
        })
        .subscribe((user) => this.router.navigate(['/users']));
    }
  }

  getOrgs(query: string, id: number[]) {
    console.log(query);
    console.log(id);
    return this.api.getOrganizations().toPromise();
  }

}
