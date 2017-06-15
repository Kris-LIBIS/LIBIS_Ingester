import { Attribute, JsonApiModel, JsonApiModelConfig } from 'ng-jsonapi';
import * as _ from 'lodash';
import { IUser } from "../datastore/users/model";

@JsonApiModelConfig({
  type: 'users'
})
export class User extends JsonApiModel {
  @Attribute()
  name: string;

  @Attribute()
  role: string;

  @Attribute()
  organizations: Array<{ id: string, name: string }>
}

@JsonApiModelConfig({
  type: 'organizations'
})
export class Organization extends JsonApiModel {
  @Attribute()
  name: string;

  @Attribute()
  code: string;

  @Attribute()
  material_flow: Object;

  @Attribute()
  ingest_dir: string;

  @Attribute()
  producer: { id: string, agent: string, password: string }

  producerName() {
    return this.producer.agent;
  }

  @Attribute()
  created_at: Date;

  @Attribute()
  users: Array<any>;

  userList() {
    return _.map(this.users, (user) => user.name).join(', ');
  }
}
