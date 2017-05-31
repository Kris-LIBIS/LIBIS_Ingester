import { NgModule } from '@angular/core';
import { RouterModule, Routes } from "@angular/router";
import { UserComponent } from "./user/user.component";
import { OrganizationComponent } from "./organization/organization.component";
import { ComponentsComponent } from "./components.component";

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
export class ComponentsRoutingModule {
}
