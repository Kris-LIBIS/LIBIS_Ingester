import { Component, OnInit } from '@angular/core';
import { Router } from "@angular/router";
import { Message } from "primeng/primeng";
import { AuthorizationService } from "../services/authorization/authorization.service";

@Component({
  selector: 'teneo-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {

  private name: string = '';
  private password: string ='';
  messages: Message[] = [];

  constructor(private auth: AuthorizationService, private router: Router) {
  }

  ngOnInit() {
  }

  onSubmit() {
    this.messages = [];
    this.auth.authenticate(this.name, this.password)
      .subscribe(
        (res) => {
          if (!res.ok) {
            this.messages.push({severity: 'error', summary: res.message, detail: res.detail});
          }
          this.router.navigate(['']).then();
        },
        (err) => {
          console.log(err);
          this.messages.push({severity: 'error', summary: err.statusText, detail: err.json().error});
          this.router.navigate(['']).then();
        });
  }
}
