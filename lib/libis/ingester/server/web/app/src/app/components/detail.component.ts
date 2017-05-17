import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FormControl, FormGroup, Validators } from "@angular/forms";
import "rxjs/add/observable/of";
import { DataModel, DataModelItem } from "./data.model";
import { Observable } from "rxjs/Observable";

@Component({
  moduleId: module.id,
  selector: 'teneo-detail',
  templateUrl: './detail.component.html',
  styleUrls: ['./detail.component.css']
})
export class DetailComponent implements OnInit {
  @Input() title: string;
  @Input() modelData: DataModel;
  @Output() cancelEvent = new EventEmitter();
  @Output() saveEvent = new EventEmitter();
  protected form: FormGroup = new FormGroup({});

  ngOnInit(): void {
    this.form = this.buildForm(this.modelData);
  }

  protected buildForm(data: DataModel): FormGroup {
    let group: any = {};
    data.items.forEach(item => this.addModelData(group, item));
    return new FormGroup(group);
  }

  private addModelData(group: any, data: DataModelItem): any {
    if (data.control.controlType() == 'group') {
      let subgroup: any = {};
      data.control.info.group.data.forEach(item => this.addModelData(subgroup, item));
      group[data.key] = new FormControl(subgroup);
    } else {
      let fc = new FormControl(data.key);
      if (data.control.required) {
        fc.setValidators(Validators.required);
      }
      group[data.key] = fc;
    }
    return group;
  }

  cancelForm(): boolean {
    this.cancelEvent.next();
    return false;
  }

  submitForm(): boolean {
    this.saveEvent.next(this.modelData);
    return false;
  }
}
