import { INITIAL_ORGANIZATON_STATE, IOrganizationState } from './organization-list';
import { INITIAL_USER_STATE, IUserState } from '../users/state';

export interface IAppState {
  user: IUserState;
  organization: IOrganizationState;
}

export const INITIAL_APP_STATE: IAppState = {
  user: INITIAL_USER_STATE,
  organization: INITIAL_ORGANIZATON_STATE
};
