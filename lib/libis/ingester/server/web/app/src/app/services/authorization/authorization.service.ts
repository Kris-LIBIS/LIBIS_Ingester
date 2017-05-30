import { Injectable } from '@angular/core';
import { Http, RequestOptions } from "@angular/http";
import { Observable } from "rxjs/Observable";
import {environment} from "../../../environments/environment";

@Injectable()
export class AuthorizationService {

  private tokenKey = 'teneoJWT';

  constructor(private http: Http) { }

  authenticate(user: string, password: string): Observable<{ok: boolean, message?: string, detail?: string}> {
    this.logout();
    let headers = new Headers();
    headers.set('Accept', 'application/json');
    headers.set('Content-Type', 'application/json');
    return this.http
      .post(environment.urlAuth, {name: user, password: password}, new RequestOptions(headers))
      .map(
        (res) => {
          console.log(`Reply: ${res}`);
          if (!res.ok) {
            return {ok: false, message: res.statusText, detail: res.json().error};
          }
          localStorage.setItem(this.tokenKey, res.json().message);
          return {ok: true, message: res.json().message};
        });
  }

  isAuthenticated?() : boolean {
    if (localStorage.getItem(this.tokenKey)) {
      return true;
    }
    return false;
  }

  logout() {
    localStorage.removeItem(this.tokenKey);
  }

  currentUser(): string {
    return 'Administrator';
  }

}
