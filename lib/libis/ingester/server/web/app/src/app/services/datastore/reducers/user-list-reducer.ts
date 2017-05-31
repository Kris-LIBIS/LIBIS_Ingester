

import { UserList } from "../status/user-list";
import { Action } from "@ngrx/store";

export const REFRESH = 'REFRESH';
export const SELECT = 'SELECT';

export function userListReducer(state: UserList, action: Action) {
  switch (action.type) {
    case REFRESH:
      return state;
    case SELECT:
      return state;
    default:
      return state;
  }
}
