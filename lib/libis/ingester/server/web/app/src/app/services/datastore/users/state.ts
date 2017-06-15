import { emptyUser, IUser } from './model';

export interface IUserMap {
  [id: string]: IUser;
}

export interface IUserState {
  ids: string[];
  users: IUserMap;
  selectedUser: IUser;
  updating: boolean;
}

export const INITIAL_USER_STATE: IUserState = {
  ids: [],
  users: {},
  selectedUser: emptyUser(),
  updating: false
};
