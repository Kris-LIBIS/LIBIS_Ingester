import { NgModule } from '@angular/core';
import { RouterModule, Routes } from "@angular/router";
import { HomeComponent } from "./home.component";
import { UserComponent } from "../components/user/user.component";
import { OrganizationComponent } from "../components/organization/organization.component";

const routes: Routes = [
  {
    path: '',
    component: ComponentsComponent,
    children: [
      {path: 'dashboard', loadChildren: './dashboard/dashboard.module#DashboardModule'},
      {path: 'users', component: UserComponent},
      {path: 'organizations', component: OrganizationComponent}
    ]
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class HomeRoutingModule {
}
