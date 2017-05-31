import { Organization } from "../../ingester-api/models";

export interface OrganizationList {
  organizations: Organization[];
  selected: Organization;
}
