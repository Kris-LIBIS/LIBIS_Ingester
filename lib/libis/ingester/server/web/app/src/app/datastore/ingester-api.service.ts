import { Injectable } from '@angular/core';
import { JsonApiDatastore, JsonApiDatastoreConfig } from "ng-jsonapi";
import { User, Organization } from './models';
import { Http, Headers, RequestOptions } from "@angular/http";
import { Observable } from "rxjs/Observable";

@Injectable()
@JsonApiDatastoreConfig({
  baseUrl: 'http://localhost:9393/api/',
  models: {
    users: User,
    organizations: Organization
  }
})
export class IngesterApiService extends JsonApiDatastore {

  constructor(http: Http, public myhttp: Http) {
    super(http);
    const headers = new Headers();
    headers.append('Accept', 'application/vnd.api+json');
    headers.append('Content-Type', 'application/json');
    this.headers = headers;
  }

  getUsers(): Observable<User[]> {
    return this.query(User).map((collection) => collection.data);
  }

  getUser(id: string): Observable<User> {
    return this.findRecord(User, id).map((document) => document.data);
  }

  saveUser(data: any, user: User): Observable<User> {
    return this.saveRecord(data, user).map((document) => document.data);
  }

  deleteUser(id: string): Observable<Boolean> {
    return this.deleteRecord(User, id).map((res) => res == null);
  }

  getUserOrgs(url: string): Observable<Organization[]> {
    return this.hasManyLink(Organization, url)
      .map((collection) => collection.data);
  }

  setUserOrgs(url: string, org_ids: Array<string>): Observable<boolean> {
    const headers = new Headers();
    headers.append('Accept', 'application/vnd.api+json');
    headers.append('Content-Type', 'application/json');
    return this.myhttp.post(url, JSON.stringify({organization_ids: org_ids}), new RequestOptions({headers: headers}))
      .map((res: any) => true);
  }

  getOrganizations(): Observable<Organization[]> {
    return this.query(Organization).map((collection) => collection.data);
  }

  getOrganization(id: string): Observable<Organization> {
    return this.findRecord(Organization, id).map((document) => document.data);
  }

}
