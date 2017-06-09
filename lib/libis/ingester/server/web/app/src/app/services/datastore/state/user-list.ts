import { User } from "../../ingester-api/models";

export interface IUserList {
  users: User[];
  loading: boolean;
  selected: User;
}
