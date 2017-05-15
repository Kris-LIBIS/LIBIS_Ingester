import { Attribute, JsonApiModel, JsonApiModelConfig } from 'ng-jsonapi';

@JsonApiModelConfig({
  type: 'users'
})
export class User extends JsonApiModel {
  @Attribute()
  name: string;

  @Attribute()
  role: string;

  @Attribute()
  organizations: Array<{id: string, name: string}>
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
  material_flow: any;

  @Attribute()
  ingest_dir: string;

  @Attribute()
  created_at: Date;
}
