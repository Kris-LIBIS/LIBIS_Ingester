import {Component, OnInit} from '@angular/core';

@Component({
  moduleId: module.id,
  selector: 'teneo-root',
  templateUrl: './app.component.html',
  styles: []
})
export class AppComponent implements OnInit {
  title = 'teneo works!';

  constructor() {
  }

  ngOnInit(): void {
  }

}
