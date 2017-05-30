import { Injectable } from '@angular/core';
import { CanActivate, Router } from "@angular/router";
import {AuthorizationService} from "../authorization/authorization.service";

@Injectable()
export class AuthGuard implements CanActivate {

  constructor(private router: Router, private auth: AuthorizationService) { }

  canActivate(): boolean {
    if (this.auth.isAuthenticated()) {
      return true;
    }
    this.router.navigate(['/login']).then();
    return false;
  }

}
