import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { AuthGuard } from "./layout/guard/auth-guard";
import { AdminGuard } from "./layout/guard/admin-guard";

const routes: Routes = [
  {path: '', loadChildren: './home/home.module#HomeModule', canActivate: [AuthGuard]},
  {path: 'login', loadChildren: './login/login.module#LoginModule'},
  {path: 'admin', loadChildren: './admin/admin.module#AdminModule', canActivate: [AuthGuard, AdminGuard]}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {
}
