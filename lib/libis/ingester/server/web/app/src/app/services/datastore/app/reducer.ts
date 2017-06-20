import { IAppState, INITIAL_APP_STATE } from './state';
import { UserActions } from '../users/actions';
import { OrganizationActions } from '../organizations/actions';
import { ActionReducer, combineReducers } from '@ngrx/store';
import { userReducer } from '../users/reducer';
import { organizationReducer } from '../organizations/reducer';
import { routerReducer } from "@ngrx/router-store";

const reducers = {
  user: userReducer,
  organization: organizationReducer,
  router: routerReducer
};

const reducer: ActionReducer<IAppState> = combineReducers(reducers);

export function appReducer(state: IAppState = INITIAL_APP_STATE, action: UserActions | OrganizationActions) {
  return reducer(state, action);
}
