import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpModule } from '@angular/http';

import { JsonApiModule } from "ng-jsonapi";

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { UserComponent } from './components/user/user.component';
import { LoginComponent } from './components/login/login.component';
import { IngesterApiService } from "./datastore/ingester-api.service";
import { UserDetailComponent } from './components/user/user-detail/user-detail.component';
import { SuiModule } from "ng2-semantic-ui";
import { OrganizationComponent } from './components/organization/organization.component';
import { OrganizationDetailComponent } from './components/organization/organization-detail/organization-detail.component';
import { ListComponent } from "./components/list.component";
import { DetailComponent } from "./components/detail.component";
import { DynamicFieldComponent } from "./components/dynamic.field.component";
import { BrowserAnimationsModule } from "@angular/platform-browser/animations";
import { ButtonModule, DropdownModule, InputTextModule, ListboxModule, MultiSelectModule } from "primeng/primeng";

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    ListComponent,
    DetailComponent,
    DynamicFieldComponent,
    UserComponent,
    UserDetailComponent,
    OrganizationComponent,
    OrganizationDetailComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    FormsModule,
    ReactiveFormsModule,
    HttpModule,
    AppRoutingModule,
    JsonApiModule,
    InputTextModule,
    ButtonModule,
    DropdownModule,
    MultiSelectModule,
    ListboxModule,
    SuiModule
  ],
  providers: [
    IngesterApiService,
    FormBuilder
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
}
