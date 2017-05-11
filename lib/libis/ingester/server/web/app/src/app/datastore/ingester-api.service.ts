import { Injectable } from '@angular/core';
import { JsonApiDatastore, JsonApiDatastoreConfig } from "ng-jsonapi";
import { User, Organization } from './models';
import { Http, Headers } from "@angular/http";
import { Observable } from "rxjs/Observable";
import { observableToBeFn } from "rxjs/testing/TestScheduler";

@Injectable()
@JsonApiDatastoreConfig({
  baseUrl: 'http://localhost:9393/api/',
  models: {
    users: User,
    organizations: Organization
  }
})
export class IngesterApiService extends JsonApiDatastore {

  constructor(http: Http) {
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

  getOrganizations(): Observable<Organization[]> {
    return this.query(Organization).map((collection) => collection.data);
  }

  getOrganization(id: string): Observable<Organization> {
    return this.findRecord(Organization, id).map((document) => document.data);
  }

}
