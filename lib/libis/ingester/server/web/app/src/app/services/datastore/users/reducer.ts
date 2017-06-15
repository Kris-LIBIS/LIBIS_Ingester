import { IUser } from './model';
import * as user from './actions';
import * as ud from 'updeep';
import { INITIAL_USER_STATE, IUserState } from './state';
import { User } from '../../ingester-api/models';

export function reducer(state = ud.freeze(INITIAL_USER_STATE), action: user.UserActions): IUserState {
  const updateState = ud(ud._, state);
  switch (action.type) {
    case user.USER_SELECT: {
      return updateState({selectedUser: action.payload});
    }
    case user.USER_LOAD: {
      return updateState({updating: true});
    }
    case user.USER_LOAD_SUCCESS: {
      const users: Array<User> = action.payload;
      return updateState({
        ids: users.map((user) => user.id),
        users: users.reduce((userMap: IUserState, user: IUser) => {
          userMap[user.id] = {
            id: user.id,
            name: user.name,
            role: user.role,
            organizations: user.organizations
          };
          return userMap;
        }, {}),
        updating: false
      });
    }
    case user.USER_LOAD_FAIL: {
      return updateState({updating: false});
    }
    case user.USER_ADD: {
      return updateState({updating: true});
    }
    case user.USER_ADD_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: (ids) => [].concat(ids, [user.id]),
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case user.USER_ADD_FAIL: {
      return updateState({updating: false});
    }
    case user.USER_UPDATE: {
      return updateState({updating: true});
    }
    case user.USER_UPDATE_SUCCESS: {
      const user: IUser = action.payload;
      if (!state.users[user.id]) {
        return updateState({updating: false});
      }
      return updateState({
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case user.USER_UPDATE_FAIL: {
      return updateState({updating: false});
    }
    case user.USER_DELETE: {
      return updateState({updating: true});
    }
    case user.USER_DELETE_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: ud.reject(id => id === user.id),
        users: ud.omit(user.id, state.users),
        updating: false
      })
    }
    case user.USER_DELETE_FAIL: {
      return updateState({updating: false});
    }
  }
}
