import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../datastore/ingester-api.service";
import { Router } from "@angular/router";

@Component({
  selector: 'teneo-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {

  private name: string = '';
  private password: string ='';
  constructor(private api: IngesterApiService, private router: Router) {
  }

  ngOnInit() {
  }

  onSubmit() {
    this.api.authenticate(this.name, this.password)
      .subscribe(
        (res) => {
          if (res) {
            localStorage.setItem('isLoggedin', 'true');
          } else {
            localStorage.setItem('isLoggedin', 'false');
          }
          this.router.navigate(['']).then();
        },
        () => {
          localStorage.setItem('isLoggedin', 'false')
          this.router.navigate(['']).then();
        });
  }
}
