import { Action } from "@ngrx/store";
import { IUser } from "./model";

export const SELECT = '[User] Select';

export const LOAD = '[User] Load';
export const LOAD_SUCCESS = '[User] Load Success';
export const LOAD_FAIL = '[User] Load Fail';
export const ADD = '[User] Add';
export const ADD_SUCCESS = '[User] Add Success';
export const ADD_FAIL = '[User] Add Fail';
export const UPDATE = '[User] Update';
export const UPDATE_SUCCESS = '[User] Update Success';
export const UPDATE_FAIL = '[User] Update Fail';
export const DELETE = '[User] Delete';
export const DELETE_SUCCESS = '[User] Delete Success';
export const DELETE_FAIL = '[User] Delete Fail';

export class SelectAction implements Action {
  readonly type = SELECT;

  constructor(public payload: IUser) {}
}

export class LoadAction implements Action {
  readonly type = LOAD;
}

export class LoadSuccessAction implements Action {
  readonly type = LOAD_SUCCESS;

  constructor(public payload: IUser[]) {}
}

export class LoadFailAction implements Action {
  readonly type = LOAD_FAIL;

  constructor(public payload: any) {}
}

export class AddAction implements Action {
  readonly type = ADD;

  constructor(public payload: IUser) {}
}

export class AddSuccessAction implements Action {
  readonly type = ADD_SUCCESS;

  constructor(public payload: IUser) {}
}

export class AddFailAction implements Action {
  readonly type = ADD_FAIL;

  constructor(public payload: IUser) {}
}

export class UpdateAction implements Action {
  readonly type = UPDATE;

  constructor(public payload: IUser) {}
}

export class UpdateSuccessAction implements Action {
  readonly type = UPDATE_SUCCESS;

  constructor(public payload: IUser) {}
}

export class UpdateFailAction implements Action {
  readonly type = UPDATE_FAIL;

  constructor(public payload: IUser) {}
}

export class DeleteAction implements Action {
  readonly type = DELETE;

  constructor(public payload: IUser) {}
}

export class DeleteSuccessAction implements Action {
  readonly type = DELETE_SUCCESS;

  constructor(public payload: IUser) {}
}

export class DeleteFailAction implements Action {
  readonly type = DELETE_FAIL;

  constructor(public payload: IUser) {}
}

export type Actions = SelectAction |
  LoadAction | LoadSuccessAction | LoadFailAction |
  AddAction| AddSuccessAction| AddFailAction|
  UpdateAction| UpdateSuccessAction| UpdateFailAction|
  DeleteAction| DeleteSuccessAction| DeleteFailAction;
