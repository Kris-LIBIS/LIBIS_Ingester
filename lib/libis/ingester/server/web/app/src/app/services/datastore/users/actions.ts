import { Action } from '@ngrx/store';
import { IUser } from './model';
import { User } from '../../ingester-api/models';

export const USER_SELECT = '[User] Select';

export const USER_LOAD = '[User] Load';
export const USER_LOAD_SUCCESS = '[User] Load Success';
export const USER_LOAD_FAIL = '[User] Load Fail';
export const USER_ADD = '[User] Add';
export const USER_ADD_SUCCESS = '[User] Add Success';
export const USER_ADD_FAIL = '[User] Add Fail';
export const USER_UPDATE = '[User] Update';
export const USER_UPDATE_SUCCESS = '[User] Update Success';
export const USER_UPDATE_FAIL = '[User] Update Fail';
export const USER_DELETE = '[User] Delete';
export const USER_DELETE_SUCCESS = '[User] Delete Success';
export const USER_DELETE_FAIL = '[User] Delete Fail';

export class UserSelectAction implements Action {
  readonly type = USER_SELECT;

  constructor(public payload: IUser) {}
}

export class UserLoadAction implements Action {
  readonly type = USER_LOAD;
}

export class UserLoadSuccessAction implements Action {
  readonly type = USER_LOAD_SUCCESS;

  constructor(public payload: User[]) {

  }
}

export class UserLoadFailAction implements Action {
  readonly type = USER_LOAD_FAIL;

  constructor(public payload: any) {}
}

export class UserAddAction implements Action {
  readonly type = USER_ADD;

  constructor(public payload: IUser) {}
}

export class UserAddSuccessAction implements Action {
  readonly type = USER_ADD_SUCCESS;

  constructor(public payload: IUser) {}
}

export class UserAddFailAction implements Action {
  readonly type = USER_ADD_FAIL;

  constructor(public payload: IUser) {}
}

export class UserUpdateAction implements Action {
  readonly type = USER_UPDATE;

  constructor(public payload: IUser) {}
}

export class UserUpdateSuccessAction implements Action {
  readonly type = USER_UPDATE_SUCCESS;

  constructor(public payload: IUser) {}
}

export class UserUpdateFailAction implements Action {
  readonly type = USER_UPDATE_FAIL;

  constructor(public payload: IUser) {}
}

export class UserDeleteAction implements Action {
  readonly type = USER_DELETE;

  constructor(public payload: IUser) {}
}

export class UserDeleteSuccessAction implements Action {
  readonly type = USER_DELETE_SUCCESS;

  constructor(public payload: IUser) {}
}

export class UserDeleteFailAction implements Action {
  readonly type = USER_DELETE_FAIL;

  constructor(public payload: IUser) {}
}

export type UserActions = UserSelectAction |
  UserLoadAction | UserLoadSuccessAction | UserLoadFailAction |
  UserAddAction| UserAddSuccessAction| UserAddFailAction|
  UserUpdateAction| UserUpdateSuccessAction| UserUpdateFailAction|
  UserDeleteAction| UserDeleteSuccessAction| UserDeleteFailAction;
