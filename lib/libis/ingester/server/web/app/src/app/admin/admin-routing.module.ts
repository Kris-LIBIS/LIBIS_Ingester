import { NgModule } from '@angular/core';
import { RouterModule, Routes } from "@angular/router";
import { UserComponent } from "../components/user/user.component";
import { OrganizationComponent } from "../components/organization/organization.component";

const routes: Routes = [
  {path: 'runs', component: UserComponent},
  {path: 'users', component: UserComponent},
  {path: 'organizations', component: OrganizationComponent},
  {path: 'workflows', component: UserComponent},
  {path: 'ingest-models', component: UserComponent},
  {path: 'representations', component: UserComponent},
  {path: 'access-rights', component: UserComponent},
  {path: 'retention-periods', component: UserComponent}
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})

export class AdminRoutingModule {
}
