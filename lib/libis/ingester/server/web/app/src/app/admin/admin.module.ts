import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminComponent } from './admin.component';
import { AdminRoutingModule } from "./admin-routing.module";
import { ComponentsModule } from "../components/components.module";

@NgModule({
  imports: [
    CommonModule,
    AdminRoutingModule,
    ComponentsModule
  ],
  declarations: [
    AdminComponent
  ]
})
export class AdminModule { }
