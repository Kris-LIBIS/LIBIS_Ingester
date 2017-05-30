import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslateModule } from "@ngx-translate/core";

import { HomeRoutingModule } from "./home-routing.module";
import { HomeComponent } from './home.component';
import { HeaderComponent } from '../layout';
import { NgbDropdownModule } from "@ng-bootstrap/ng-bootstrap";
import { SidebarComponent } from "../layout/sidebar/sidebar.component";

@NgModule({
  imports: [
    CommonModule,
    NgbDropdownModule.forRoot(),
    TranslateModule,
    HomeRoutingModule
  ],
  declarations: [
    HomeComponent,
    HeaderComponent,
    SidebarComponent,
  ]
})
export class HomeModule { }
