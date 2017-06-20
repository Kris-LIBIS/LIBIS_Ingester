import { INITIAL_USER_STATE, IUserState } from '../users/state';
import { INITIAL_ORGANIZATION_STATE, IOrganizationState } from "../organizations/state";

export interface IAppState {
  user: IUserState;
  organization: IOrganizationState
}

export const INITIAL_APP_STATE: IAppState = {
  user: INITIAL_USER_STATE,
  organization: INITIAL_ORGANIZATION_STATE
};

