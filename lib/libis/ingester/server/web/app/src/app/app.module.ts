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

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    UserComponent,
    UserDetailComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    ReactiveFormsModule,
    HttpModule,
    AppRoutingModule,
    JsonApiModule,
    SuiModule
  ],
  providers: [
    IngesterApiService,
    FormBuilder
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
