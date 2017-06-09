export interface IUser {
  id: string;
  name: string;
  role: string;
  organizations: Array<{ id: string, name: string }>;
}
