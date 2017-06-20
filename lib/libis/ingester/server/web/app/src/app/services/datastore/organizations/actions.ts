import { Action } from '@ngrx/store';
import { IOrganization } from './model';
import { Organization } from '../../ingester-api/models';

export const ORGANIZATION_SELECT = '[Organization] Select';

export const ORGANIZATION_LOAD = '[Organization] Load';
export const ORGANIZATION_LOAD_SUCCESS = '[Organization] Load Success';
export const ORGANIZATION_LOAD_FAIL = '[Organization] Load Fail';
export const ORGANIZATION_ADD = '[Organization] Add';
export const ORGANIZATION_ADD_SUCCESS = '[Organization] Add Success';
export const ORGANIZATION_ADD_FAIL = '[Organization] Add Fail';
export const ORGANIZATION_UPDATE = '[Organization] Update';
export const ORGANIZATION_UPDATE_SUCCESS = '[Organization] Update Success';
export const ORGANIZATION_UPDATE_FAIL = '[Organization] Update Fail';
export const ORGANIZATION_DELETE = '[Organization] Delete';
export const ORGANIZATION_DELETE_SUCCESS = '[Organization] Delete Success';
export const ORGANIZATION_DELETE_FAIL = '[Organization] Delete Fail';

export class OrganizationSelectAction implements Action {
  readonly type = ORGANIZATION_SELECT;

  constructor(public payload: IOrganization) {}
}

export class OrganizationLoadAction implements Action {
  readonly type = ORGANIZATION_LOAD;
}

export class OrganizationLoadSuccessAction implements Action {
  readonly type = ORGANIZATION_LOAD_SUCCESS;

  constructor(public payload: Organization[]) {

  }
}

export class OrganizationLoadFailAction implements Action {
  readonly type = ORGANIZATION_LOAD_FAIL;

  constructor(public payload: any) {}
}

export class OrganizationAddAction implements Action {
  readonly type = ORGANIZATION_ADD;

  constructor(public payload: IOrganization) {}
}

export class OrganizationAddSuccessAction implements Action {
  readonly type = ORGANIZATION_ADD_SUCCESS;

  constructor(public payload: IOrganization) {}
}

export class OrganizationAddFailAction implements Action {
  readonly type = ORGANIZATION_ADD_FAIL;

  constructor(public payload: IOrganization) {}
}

export class OrganizationUpdateAction implements Action {
  readonly type = ORGANIZATION_UPDATE;

  constructor(public payload: IOrganization) {}
}

export class OrganizationUpdateSuccessAction implements Action {
  readonly type = ORGANIZATION_UPDATE_SUCCESS;

  constructor(public payload: IOrganization) {}
}

export class OrganizationUpdateFailAction implements Action {
  readonly type = ORGANIZATION_UPDATE_FAIL;

  constructor(public payload: IOrganization) {}
}

export class OrganizationDeleteAction implements Action {
  readonly type = ORGANIZATION_DELETE;

  constructor(public payload: IOrganization) {}
}

export class OrganizationDeleteSuccessAction implements Action {
  readonly type = ORGANIZATION_DELETE_SUCCESS;

  constructor(public payload: IOrganization) {}
}

export class OrganizationDeleteFailAction implements Action {
  readonly type = ORGANIZATION_DELETE_FAIL;

  constructor(public payload: IOrganization) {}
}

export type OrganizationActions = OrganizationSelectAction |
  OrganizationLoadAction | OrganizationLoadSuccessAction | OrganizationLoadFailAction |
  OrganizationAddAction| OrganizationAddSuccessAction| OrganizationAddFailAction|
  OrganizationUpdateAction| OrganizationUpdateSuccessAction| OrganizationUpdateFailAction|
  OrganizationDeleteAction| OrganizationDeleteSuccessAction| OrganizationDeleteFailAction;
