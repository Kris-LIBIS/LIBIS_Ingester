import { Component, OnInit } from '@angular/core';
import { IngesterApiService } from "../../datastore/ingester-api.service";

@Component({
  selector: 'teneo-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

  constructor(private api: IngesterApiService) { }

  ngOnInit() {
  }

  onSubmit(data: any) {
    
  }
}
