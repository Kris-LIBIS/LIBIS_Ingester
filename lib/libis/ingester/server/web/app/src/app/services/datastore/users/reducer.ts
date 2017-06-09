import { IUser } from "./model";
import * as user from './actions';
import ud = require('updeep');

export type UserMap = { [id: string]: IUser };

export interface State {
  ids: string[];
  users: UserMap;
  selectedUserId: string | null;
  updating: boolean;
}

export const initialState: State = {
  ids: [],
  users: {},
  selectedUserId: null,
  updating: false
};

export function reducer(state = ud.freeze(initialState), action: user.Actions): State {
  let updateState = ud(ud._, state);
  switch (action.type) {
    case user.SELECT: {
      return updateState({selectedUserId: action.payload.id});
    }
    case user.LOAD: {
      return updateState({updating: true});
    }
    case user.LOAD_SUCCESS: {
      const users: Array<IUser> = action.payload;
      return updateState({
        ids: users.map((user) => user.id),
        users: users.reduce((userMap: UserMap, user: IUser) => {
          return ud({[user.id]: user}, userMap);
        }, {}),
        updating: false
      });
    }
    case user.LOAD_FAIL: {
      return updateState({updating: false});
    }
    case user.ADD: {
      return updateState({updating: true});
    }
    case user.ADD_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: (ids) => [].concat(ids, [user.id]),
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case user.ADD_FAIL: {
      return updateState({updating: false});
    }
    case user.UPDATE: {
      return updateState({updating: true});
    }
    case user.UPDATE_SUCCESS: {
      const user: IUser = action.payload;
      if (!state.users[user.id]) {
        return updateState({updating: false});
      }
      return updateState({
        users: ud({[user.id]: user}, state.users),
        updating: false
      });
    }
    case user.UPDATE_FAIL: {
      return updateState({updating: false});
    }
    case user.DELETE: {
      return updateState({updating: true});
    }
    case user.DELETE_SUCCESS: {
      const user: IUser = action.payload;
      return updateState({
        ids: ud.reject(id => id == user.id),
        users: ud.omit(user.id, state.users),
        updating: false
      })
    }
    case user.DELETE_FAIL: {
      return updateState({updating: false});
    }
  }
}
