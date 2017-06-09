

import { IUserList } from "../state/user-list";
import { Action } from "@ngrx/store";

export const REFRESH_USERS = 'REFRESH_USERS';
export const SELECT_USER = 'SELECT_USER';

export function reducer(state: IUserList, {type, payload } ) {
  switch (type) {
    case REFRESH_USERS:
      return payload;
    case SELECT_USER:
      return state;
    default:
      return state;
  }
}
