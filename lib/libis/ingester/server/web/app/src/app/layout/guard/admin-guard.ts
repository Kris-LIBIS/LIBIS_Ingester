import { Injectable } from "@angular/core";
import { CanActivate, Router } from "@angular/router";

@Injectable()
export class AdminGuard implements CanActivate {
  private admin: boolean = true;

  constructor(private router: Router) {}

  canActivate(): boolean {
    // TODO: check for admin rights
    if (this.admin) {
      return true;
    }

    this.router.navigate(['/home']).then();
    return false;
  }
}
