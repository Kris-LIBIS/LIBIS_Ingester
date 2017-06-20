import { IUser } from "../users/model";

export interface IOrganization {
  id: string;
  name: string;
  users?: IUser[];
}

export function newOrganization(): IOrganization {
  return {
    id: null,
    name: '',
    users: []
  };
}
