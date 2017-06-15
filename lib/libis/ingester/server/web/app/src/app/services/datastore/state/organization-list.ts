import { Organization } from "../../ingester-api/models";

export interface IOrganizationState {
  ids: number[];
  organizations: Organization[];
  updating: boolean;
  selected: Organization;
}

export const INITIAL_ORGANIZATON_STATE = {
  ids: [],
  organizations: [],
  updating: false,
  selected: undefined
}
