import { isUndefined } from 'util';
import * as _ from 'lodash';

export class DataModel {
  constructor(public items: DataModelItem[] = []) {
  }

  addItem(label: string, key: string): DataModelItem {
    const item = new DataModelItem(label, key);
    this.items.push(item);
    return item;
  }

  item(key: string): DataModelItem {
    let found: DataModelItem = null;
    this.items.forEach((item) => {
      if (item.key === key) {
        found = item;
      }
    });
    return found;
  }

  keys(): string[] {
    return _.map(this.items, 'key');
  }

  mainItem(): DataModelItem {
    const foundKeys: Array<string> = _.intersection(this.keys(), ['name', '_name', 'id', '_id']);
    if (foundKeys[0] != null) {
      return this.item(foundKeys[0]);
    }
    return this.items[0];
  }
}

export class DataModelItem {
  constructor(public label: string,
              public key: string,
              public control?: DataModelControl) {
  }

  setControl(required: boolean = false, placeholder = this.label): DataModelControl {
    this.control = new DataModelControl(required, placeholder);
    return this.control;
  }

  hasControl(): boolean {
    return (!isUndefined(this.control));
  }
}

export class DataModelControl {
  constructor(public required: boolean = false,
              public placeholder: string = '',
              public info?: DataModelControlInfo) {
  }

  setInfo(type: string): DataModelControlInfo {
    this.info = new DataModelControlInfo(type);
    return this.info;
  }

  controlType(): string {
    return this.info.controlType;
  }
}

export class DataModelControlInfo {
  constructor(public controlType: string,
              public textbox?: DataModelTextBox,
              public select?: DataModelSelect,
              public group?: DataModelGroup) {
  }

  setTextBox(type: string = 'text'): DataModelTextBox {
    if (this.controlType !== 'textbox') {
      throw new Error('DataModelTextBox requires controlType=\'textbox');
    }
    this.textbox = new DataModelTextBox(type);
    return this.textbox;
  }

  setSelect(multiselect: boolean = false): DataModelSelect {
    if (this.controlType !== 'dropdown' && this.controlType !== 'checklist') {
      throw new Error('DataModelSelect requires controlType=\'dropdown\' or \'checklist\'');
    }
    this.select = new DataModelSelect([], multiselect);
    return this.select;
  }

  setGroup(): DataModelGroup {
    if (this.controlType !== 'group') {
      throw new Error('DataModelGroup requires controlType=\'group\'');
    }
    this.group = new DataModelGroup();
    return this.group;
  }
}

export class DataModelTextBox {
  constructor(public type: string = 'text') {
  }
}

export class ListItem {
  constructor(public label: string = '',
              public value: any = '',
              public selected: boolean = false) {
  }

  toggle(): boolean {
    this.selected = !this.selected;
    return this.selected;
  }
}

export class DataModelSelect {
  constructor(public list: Array<ListItem> = [],
              public multiselect: boolean = false) {
  }

  addItem(label: string, value: any = null, selected: boolean = false): DataModelSelect {
    this.list.push(new ListItem(label, value, selected));
    return this;
  }

  toggle(item: ListItem) {
    if (!this.multiselect && !item.selected) {
      this.list.forEach((listItem) => listItem.selected = false)
    }
    item.toggle();
  }
}

export class DataModelGroup extends DataModelControlInfo {
  constructor(public data: DataModelItem[] = []) {
    super('group');
  }
}

