import { Component, OnInit } from '@angular/core';
import { TranslateService } from "@ngx-translate/core";
import { AuthorizationService } from "../../services/authorization/authorization.service";

@Component({
  moduleId: module.id,
  selector: 'teneo-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent implements OnInit {

  userName: string;

  constructor(private translate: TranslateService, private auth: AuthorizationService) { }

  ngOnInit() {
    this.userName = this.auth.currentUser();
  }

  toggleSidebar() {
    const dom: any = document.querySelector('body');
    dom.classList.toggle('push-right');
  }

  onLoggedout() {
    this.auth.logout();
  }

  changeLang(language: string) {
    this.translate.use(language);
  }

}
