import {Component, OnInit} from '@angular/core';
import {IngesterApiService} from "../../../datastore/ingester-api.service";
import {ActivatedRoute, Params, Router} from "@angular/router";
import "rxjs/add/operator/switchMap";
import "rxjs/add/operator/do";
import "rxjs/add/operator/toPromise";
import {FormBuilder, FormGroup, Validators} from "@angular/forms";
import {AttributeMetadata} from "ng-jsonapi";
import {Organization, User} from "../../../datastore/models";
import {Observable} from "rxjs/Observable";
import "rxjs/add/observable/of";
import * as _ from 'lodash';

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
  isOpen: boolean = false;

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
        if (id === 'new') {
          return Observable.of(new User(this.api, {}));
        }
        return this.api.getUser(id);
      })
      .do((user) => {
        this.form.controls['name'].patchValue(user.name);
        this.form.controls['role'].patchValue(user.role);
      })
      .switchMap((user) => {
        if (user.links['organizations']) {
          return this.api.getUserOrgs(user.links['organizations'].href);
        }
        return Observable.of([]);
      })
      .subscribe((orgs: Organization[]) => {
        orgs.forEach((org) => {
          this.selectedOrgs.push(org);
        });
      });
  }

  private observableUser(): Observable<User> {
    if (this.id === 'new') {
      return Observable.of(new User(this.api));
    }
    return this.api.getUser(this.id);
  }

  onSubmit(form: FormGroup) {
    console.log(form);
    this.observableUser()
      .switchMap((user) => {
        user.name = form.getRawValue().name;
        user.role = form.getRawValue().role;
        user.organizations = _.map(this.selectedOrgs, (org) => new Object({id: org.id, name: org.name}));
        return this.api.saveUser(user[AttributeMetadata], user)
      })
      .subscribe(
        (user) => this.router.navigate(['/users']),
        (error) => {
          console.log(error);
          this.router.navigate(['/users']);
        },
        () => this.router.navigate((['/users']))
      );
  }

  selectedIndex(org): number {
    return _.findIndex(this.selectedOrgs, (o) => o.id === org.id);
  }

  isSelected(org): boolean {
    return this.selectedIndex(org) > -1;
  }

  toggleSelect(org): void {
    const index = this.selectedIndex(org);
    if (index > -1) {
      this.selectedOrgs.splice(index, 1);
    } else {
      this.selectedOrgs.push(org);
    }
  }

}
