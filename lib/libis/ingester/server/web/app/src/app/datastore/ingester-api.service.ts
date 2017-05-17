import { Injectable } from '@angular/core';
import { JsonApiDatastore, JsonApiDatastoreConfig, JsonApiModel, ModelType } from "ng-jsonapi";
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
}
