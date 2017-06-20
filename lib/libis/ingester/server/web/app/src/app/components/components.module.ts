import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserComponent } from "./user/user.component";
import { OrganizationComponent } from "./organization/organization.component";
import { ListComponent } from "./list/list.component";
import { DetailComponent } from "./detail/detail.component";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { DynamicFieldComponent } from "./dynform/dynamic.field.component";
import {
  DataTableModule, DropdownModule, ListboxModule, MultiSelectModule, PanelModule,
  SharedModule
} from "primeng/primeng";
import { RouterModule } from "@angular/router";
import { OrganizationDetailComponent } from "./organization/organization-detail/organization-detail.component";
import { ComponentsComponent } from './components.component';
import { UserDetailComponent } from "./user/user-detail/user-detail.component";
import { CardComponent } from './card/card.component';
import { ComponentsRoutingModule } from "./components.routing.module";
import { UserListComponent } from './user/user-list/user-list.component';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    DropdownModule,
    MultiSelectModule,
    ListboxModule,
    RouterModule,
    ComponentsRoutingModule,
    PanelModule,
    DataTableModule,
    SharedModule
  ],
  declarations: [
    ListComponent,
    DetailComponent,
    DynamicFieldComponent,
    UserComponent,
    UserDetailComponent,
    OrganizationComponent,
    OrganizationDetailComponent,
    ComponentsComponent,
    CardComponent,
    UserListComponent
  ],
  exports: [
    UserComponent,
    OrganizationComponent
  ]
})
export class ComponentsModule { }
