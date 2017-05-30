import {Component, OnInit} from '@angular/core';
// import {MenuItem} from "primeng/primeng";
import {TranslateService} from "@ngx-translate/core";

@Component({
  moduleId: module.id,
  selector: 'teneo-root',
  templateUrl: './app.component.html',
  styles: []
})
export class AppComponent implements OnInit {
  // private menuItems: MenuItem[];
  // private sidebarOpen: boolean;
  // private sidebarMode = 'push';
  // private sidebarPosition = 'left';
  // private sidebarCloseOnClick = true;
  // private sidebarCloseOnKey = true;

  constructor(private translate: TranslateService) {
    translate.addLangs(['en', 'nl', 'fr']);
    translate.setDefaultLang('en');

    const browserLang = translate.getBrowserLang();
    translate.use(browserLang.match(/en|nl|fr/) ? browserLang : 'en');
  }

  ngOnInit(): void {
    //   this.menuItems = [{
    //     label: 'Runs',
    //     icon: 'fa-circle-o-notch fa-spin',
    //     routerLink: ['/runs']
    //   }, {
    //     label: 'Setup',
    //     items: [
    //       {label: 'Users', icon: 'fa-user', routerLink: ['/users']},
    //       {label: 'Organizations', icon: 'fa-users', routerLink: ['/organizations']},
    //       {label: 'Workflows', icon: 'fa-sitemap', routerLink: ['/workflows']},
    //       {label: 'Ingest Models', icon: 'fa-linode', routerLink: ['/ingest-models']},
    //       {label: 'Representation Infos', icon: 'fa-window-restore', routerLink: ['/representations']},
    //       {label: 'Access Rights', icon: 'fa-lock', routerLink: ['/access-rights']},
    //       {label: 'Retention Periods', icon: 'fa-trash', routerLink: ['/retention-periods']}
    //     ]
    //   }, {
    //     label: 'Admin',
    //     items: [
    //       {label: 'Processes', icon: 'fa-bolt', routerLink: ['/processes']},
    //       {label: 'Queues', icon: 'fa-stack-overflow', routerLink: ['/queues']}
    //     ]
    //   }];
    //   this.sidebarOpen = false;
  }

  // toggleSidebar(): void {
  //   this.sidebarOpen = !this.sidebarOpen;
  // }

}
