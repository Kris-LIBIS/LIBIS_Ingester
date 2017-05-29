import { Injectable } from '@angular/core';
import { JsonApiDatastore, JsonApiDatastoreConfig, JsonApiModel, ModelType } from "ng-jsonapi";
import { User, Organization } from './models';
import { Http, Headers, RequestOptions } from "@angular/http";
import { Observable } from "rxjs/Observable";
import "rxjs/add/observable/forkJoin";

@Injectable()
@JsonApiDatastoreConfig({
  baseUrl: 'http://localhost:9393/api/',
  models: {
    users: User,
    organizations: Organization
  }
})
export class IngesterApiService extends JsonApiDatastore {

  private myHttp: Http;

  constructor(http: Http) {
    super(http);
    this.myHttp = http;
    const headers = new Headers();
    headers.append('Accept', 'application/vnd.api+json');
    headers.append('Content-Type', 'application/json');
    this.headers = headers;
  }

  getObjectList<T extends JsonApiModel>(modelType: ModelType<T>): Observable<T[]> {
    return this.query(modelType).map((collection) => collection.data);
  }

  getObject<T extends JsonApiModel>(modelType: ModelType<T>, id: string): Observable<T> {
    return this.findRecord(modelType, id).map((document) => document.data);
  }

  saveObject<T extends JsonApiModel>(data: any, obj: T) {
    return this.saveRecord(data, obj).map((document) => document.data);
  }

  deleteObject<T extends JsonApiModel>(modelType: ModelType<T>, obj: T): Observable<boolean> {
    return this.deleteRecord(modelType, obj.id).map((res) => res == null);
  }

  getHasMany<T extends JsonApiModel>(modelType: ModelType<T>, url: string): Observable<T[]> {
    return this.hasManyLink(modelType, url).map((collection) => collection.data);
  }

  getBelongsTo<T extends JsonApiModel>(modelType: ModelType<T>, url: string): Observable<T> {
    return this.belongsToLink(modelType, url).map((document) => document.data);
  }

  authenticate(user: string, password: string): Observable<{ok: boolean, message?: string, detail?: string}> {
    localStorage.removeItem('teneoJWT');
    let headers = new Headers();
    headers.set('Accept', 'application/json');
    headers.set('Content-Type', 'application/json');
    return this.myHttp
      .post(this.getBaseUrl() + 'auth', {name: user, password: password}, this.getOptions(headers))
      .map(
        (res) => {
          console.log(`Reply: ${res}`);
          if (!res.ok) {
            return {ok: false, message: res.statusText, detail: res.json().error};
          }
          localStorage.setItem('isLoggedin', 'true');
          localStorage.setItem('teneoJWT', res.json().message);
          return {ok: true, message: res.json().message};
        });
  }
}
