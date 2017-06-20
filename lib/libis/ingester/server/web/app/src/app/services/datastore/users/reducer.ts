import { IUser, newUser } from './model';
import * as ud from 'updeep';
import * as _ from 'lodash';
import { INITIAL_USER_STATE, IUserState } from './state';
import { User } from '../../ingester-api/models';
import {
  USER_ADD, USER_ADD_FAIL, USER_ADD_SUCCESS, USER_DELETE, USER_DELETE_FAIL, USER_DELETE_SUCCESS, USER_LOAD,
  USER_LOAD_FAIL,
  USER_LOAD_SUCCESS, USER_SELECT,
  USER_UPDATE,
  USER_UPDATE_FAIL,
  USER_UPDATE_SUCCESS,
  UserActions
} from "./actions";

export function userReducer(state = ud.freeze(INITIAL_USER_STATE), action: UserActions): IUserState {
  const updateState = ud(ud._, state);
  switch (action.type) {
    case USER_SELECT: {
      return updateState({selectedUser: action.payload});
    }
    case USER_LOAD: {
      return updateState({updating: true});
    }
    case USER_LOAD_SUCCESS: {
      return updateState({
        users: action.payload.map((user: User) => _.pick(user, ['id', 'name', 'role', 'organizations'])),
        updating: false
      });
    }
    case USER_LOAD_FAIL: {
      return updateState({updating: false});
    }
    case USER_ADD: {
      return updateState({updating: true});
    }
    case USER_ADD_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: (ids) => [].concat(ids, [user.id]),
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case USER_ADD_FAIL: {
      return updateState({updating: false});
    }
    case USER_UPDATE: {
      return updateState({updating: true});
    }
    case USER_UPDATE_SUCCESS: {
      const user: IUser = action.payload;
      if (!state.users[user.id]) {
        return updateState({updating: false});
      }
      return updateState({
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case USER_UPDATE_FAIL: {
      return updateState({updating: false});
    }
    case USER_DELETE: {
      return updateState({updating: true});
    }
    case USER_DELETE_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: ud.reject(id => id === user.id),
        users: ud.omit(user.id, state.users),
        updating: false
      })
    }
    case USER_DELETE_FAIL: {
      return updateState({updating: false});
    }
    default: {
      return state;
    }
  }
}
