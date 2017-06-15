import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { DataModel } from '../data.model';

@Component({
  moduleId: module.id,
  selector: 'teneo-list',
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.scss']
})
export class ListComponent implements OnInit {

  @Input() objects: Array<any>;
  @Input() title: string;
  @Input() link: string;
  @Input() dataModel: DataModel;
  @Output() deleteEvent: EventEmitter<any> = new EventEmitter();
  @Output() editEvent: EventEmitter<any> = new EventEmitter();

  ngOnInit(): void {
  }

  protected value(obj: any, key: string) {
    if (!obj) {
      return '';
    }
    if (typeof(obj[key]) === 'function') {
      return obj[key]();
    }
    if (obj.hasOwnProperty(key)) {
      return obj[key];
    }
    return '';
  }

  protected editObject(object: any) {
    this.editEvent.emit(object);
  }

  protected deleteObject(object: any) {
    this.deleteEvent.emit(object);
  }
}
