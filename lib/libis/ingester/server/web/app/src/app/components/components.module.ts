import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserComponent } from "./user/user.component";
import { OrganizationComponent } from "./organization/organization.component";
import { ListComponent } from "./list/list.component";
import { DetailComponent } from "./detail/detail.component";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { DynamicFieldComponent } from "./dynform/dynamic.field.component";
import { DropdownModule, ListboxModule, MultiSelectModule } from "primeng/primeng";
import { RouterModule } from "@angular/router";
import { OrganizationDetailComponent } from "./organization/organization-detail/organization-detail.component";

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    DropdownModule,
    MultiSelectModule,
    ListboxModule,
    RouterModule
  ],
  declarations: [
    ListComponent,
    DetailComponent,
    DynamicFieldComponent,
    UserComponent,
    OrganizationComponent,
    OrganizationDetailComponent
  ],
  exports: [
    UserComponent,
    OrganizationComponent
  ]
})
export class ComponentsModule { }
