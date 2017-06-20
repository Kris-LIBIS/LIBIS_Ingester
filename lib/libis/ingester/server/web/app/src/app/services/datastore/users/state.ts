import { newUser, IUser } from './model';

export interface IUserState {
  users: IUser[];
  selectedUser: IUser;
  updating: boolean;
}

export const INITIAL_USER_STATE: IUserState = {
  users: [],
  selectedUser: newUser(),
  updating: false
};
