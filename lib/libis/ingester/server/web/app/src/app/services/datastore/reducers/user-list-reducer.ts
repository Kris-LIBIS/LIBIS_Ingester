

import { UserList } from "../status/user-list";
import { Action } from "@ngrx/store";

export const REFRESH_USERS = 'REFRESH_USERS';
export const SELECT_USER = 'SELECT_USER';

export function userListReducer(state: UserList, {type, payload } ) {
  switch (type) {
    case REFRESH_USERS:
      return payload;
    case SELECT_USER:
      return state;
    default:
      return state;
  }
}
