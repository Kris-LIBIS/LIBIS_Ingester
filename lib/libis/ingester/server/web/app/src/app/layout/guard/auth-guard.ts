import { Injectable } from '@angular/core';
import { CanActivate, Router } from "@angular/router";

@Injectable()
export class AuthGuard implements CanActivate {

  constructor(private router: Router) { }

  canActivate(): boolean {
    let jwt = localStorage.getItem('teneoJWT');
    if (jwt) {
      return true;
    }
    this.router.navigate(['/login']).then();
    return false;
  }

}
