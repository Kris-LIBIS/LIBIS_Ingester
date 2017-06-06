import { NgModule } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { Http, HttpModule } from '@angular/http';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from "@angular/platform-browser/animations";

import { TranslateModule, TranslateLoader } from "@ngx-translate/core";
import { TranslateHttpLoader } from "@ngx-translate/http-loader";

import { combineReducers, StoreModule } from "@ngrx/store";
import { compose } from "@ngrx/core/compose";
import { localStorageSync } from "ngrx-store-localstorage";

// AoT requires an exported function for factories
export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, '/assets/i18n/', '.json');
}

import { JsonApiModule } from "ng-jsonapi";

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AuthGuard } from "./services/guard/auth-guard";
import { AdminGuard } from "./services/guard/admin-guard";
import { IngesterApiService } from "./services/ingester-api/ingester-api.service";
import { AuthorizationService } from "./services/authorization/authorization.service";
import { userListReducer } from "./services/datastore/reducers/user-list-reducer";


@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpModule,
    StoreModule.provideStore(
      compose(
        localStorageSync({
          keys: [],
          rehydrate: true,
          removeOnUndefined: true,
          storageKeySerializer: (key) => 'teneo_' + key
        }),
        combineReducers
      )({userList: userListReducer})
    ),
    AppRoutingModule,
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: HttpLoaderFactory,
        deps: [Http]
      }
    }),
    JsonApiModule
  ],
  providers: [
    FormBuilder,
    IngesterApiService,
    AuthorizationService,
    AuthGuard,
    AdminGuard
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
}
