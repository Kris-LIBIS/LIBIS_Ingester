import { UserList } from "./user-list";
import { OrganizationList } from "./organization-list";

export interface AppState {
  users: UserList;
  organizations: OrganizationList;
}
