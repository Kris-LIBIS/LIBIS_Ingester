export interface IUser {
  id: string;
  name: string;
  role: string;
  organizations: Array<{ id: string, name: string }>;
}

export function emptyUser(): IUser {
  return {
    id: null,
    name: '',
    role: 'submitter',
    organizations: []
  }
}
