import { NgModule } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { Http, HttpModule } from '@angular/http';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { TranslateModule, TranslateLoader } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

import { StoreModule } from '@ngrx/store';

// AoT requires an exported function for factories
export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, '/assets/i18n/', '.json');
}

import { JsonApiModule } from 'ng-jsonapi';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AuthGuard } from './services/guard/auth-guard';
import { AdminGuard } from './services/guard/admin-guard';
import { IngesterApiService } from './services/ingester-api/ingester-api.service';
import { AuthorizationService } from './services/authorization/authorization.service';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';

import { EffectsModule } from '@ngrx/effects';

import { UserEffects } from './services/datastore/users/effects';
import { DataTableModule, SharedModule } from 'primeng/primeng';
import { OrganizationEffects } from './services/datastore/organizations/effects';
import { appReducer } from './services/datastore/app/reducer';
import { RouterStoreModule } from "@ngrx/router-store";


@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpModule,
    AppRoutingModule,
    StoreModule.provideStore(appReducer),
    RouterStoreModule.connectRouter(),
    StoreDevtoolsModule.instrumentOnlyWithExtension(),
    EffectsModule.run(UserEffects),
    EffectsModule.run(OrganizationEffects),
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: HttpLoaderFactory,
        deps: [Http]
      }
    }),
    JsonApiModule,
    DataTableModule,
    SharedModule
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
