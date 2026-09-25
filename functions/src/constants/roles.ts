export const ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  EMPLOYEE: 'employee',
  // Browser-based Platform Admin portal (Milestone 3D-B+). Distinct from
  // the mobile super_admin workflow — platform_admin can review
  // organization registrations but has no access to mobile admin features.
  PLATFORM_ADMIN: 'platform_admin',
  // Organization registration applicant (3D-C follow-up). Authenticated
  // user whose registration application is still under review — has NO
  // admin/HRMS access until the organization is activated.
  ORG_APPLICANT: 'org_applicant',
} as const;