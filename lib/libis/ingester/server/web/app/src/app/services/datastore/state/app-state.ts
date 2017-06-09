import { OrganizationList } from "./organization-list";
import { IUserState } from "../users/state";

export interface IAppState {
  user: IUserState;
  organization: OrganizationList;
}
