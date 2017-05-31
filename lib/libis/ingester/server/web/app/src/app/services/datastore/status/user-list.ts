import { User } from "../../ingester-api/models";

export interface UserList {
  users: User[];
  selected: User;
}
