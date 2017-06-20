import { IOrganization, newOrganization } from "./model";

export interface IOrganizationState {
  organizations: IOrganization[];
  selectedOrganization: IOrganization;
  updating: boolean;
}

export const INITIAL_ORGANIZATION_STATE: IOrganizationState = {
  organizations: [],
  selectedOrganization: newOrganization(),
  updating: false
};
