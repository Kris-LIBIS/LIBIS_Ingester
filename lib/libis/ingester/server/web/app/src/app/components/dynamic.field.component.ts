import { Component, Input } from '@angular/core';
import { FormControl } from "@angular/forms";
import { DataModelItem } from "./data.model";

@Component({
  moduleId: module.id,
  selector: 'teneo-dyn-field',
  templateUrl: './dynamic.field.component.html',
  styles: []
})
export class DynamicFieldComponent {

  @Input() control: FormControl;
  @Input() data: DataModelItem;

}
