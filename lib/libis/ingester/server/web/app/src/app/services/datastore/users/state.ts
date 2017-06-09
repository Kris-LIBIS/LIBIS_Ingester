import { IUser } from "./model";

export interface IUserState {
  users: { [key: number]: IUser };
}
