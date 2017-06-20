import { IOrganization } from "../organizations/model";

export interface IUser {
  id: string;
  name: string;
  role?: string;
  organizations?: IOrganization[];
}

export function newUser(): IUser {
  return {
    id: null,
    name: '',
    role: 'submitter',
    organizations: []
  }
}
