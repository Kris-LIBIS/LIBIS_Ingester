import { IOrganization, newOrganization } from './model';
import * as ud from 'updeep';
import * as _ from 'lodash';
import { INITIAL_ORGANIZATION_STATE, IOrganizationState } from './state';
import { Organization, User } from '../../ingester-api/models';
import {
  ORGANIZATION_ADD, ORGANIZATION_ADD_FAIL, ORGANIZATION_ADD_SUCCESS, ORGANIZATION_DELETE, ORGANIZATION_DELETE_FAIL, ORGANIZATION_DELETE_SUCCESS, ORGANIZATION_LOAD,
  ORGANIZATION_LOAD_FAIL,
  ORGANIZATION_LOAD_SUCCESS, ORGANIZATION_SELECT,
  ORGANIZATION_UPDATE,
  ORGANIZATION_UPDATE_FAIL,
  ORGANIZATION_UPDATE_SUCCESS,
  OrganizationActions
} from "./actions";

export function organizationReducer(state = ud.freeze(INITIAL_ORGANIZATION_STATE), action: OrganizationActions): IOrganizationState {
  const updateState = ud(ud._, state);
  switch (action.type) {
    case ORGANIZATION_SELECT: {
      return updateState({selectedOrganization: action.payload});
    }
    case ORGANIZATION_LOAD: {
      return updateState({updating: true});
    }
    case ORGANIZATION_LOAD_SUCCESS: {
      return updateState({
        organizations: action.payload.map((org: Organization) => _.pick(org, ['id', 'name', 'users'])),
        updating: false
      });
    }
    case ORGANIZATION_LOAD_FAIL: {
      return updateState({updating: false});
    }
    case ORGANIZATION_ADD: {
      return updateState({updating: true});
    }
    case ORGANIZATION_ADD_SUCCESS: {
      const user: IOrganization = action.payload;
      return updateState({
        ids: (ids) => [].concat(ids, [user.id]),
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case ORGANIZATION_ADD_FAIL: {
      return updateState({updating: false});
    }
    case ORGANIZATION_UPDATE: {
      return updateState({updating: true});
    }
    case ORGANIZATION_UPDATE_SUCCESS: {
      const user: IOrganization = action.payload;
      if (!state.users[user.id]) {
        return updateState({updating: false});
      }
      return updateState({
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case ORGANIZATION_UPDATE_FAIL: {
      return updateState({updating: false});
    }
    case ORGANIZATION_DELETE: {
      return updateState({updating: true});
    }
    case ORGANIZATION_DELETE_SUCCESS: {
      const user: IOrganization = action.payload;
      return updateState({
        ids: ud.reject(id => id === user.id),
        users: ud.omit(user.id, state.users),
        updating: false
      })
    }
    case ORGANIZATION_DELETE_FAIL: {
      return updateState({updating: false});
    }
    default: {
      return state;
    }
  }
}
