import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from "@angular/router";
import { HeaderComponent } from "../layout/header/header.component";

@Component({
  selector: 'teneo-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {

  constructor(public router: Router) {
  }

  ngOnInit() {
    if (this.router.url === '/') {
      this.router.navigate(['/dashboard']).then();
    }
  }

}
