# Application Scope Document with Gap Analysis
## Enterprise Product Model — Human Resource Management System (HRMS)

---

## 1. Document Control

| Field | Value |
|-------|-------|
| **Document Title** | Application Scope Document with Gap Analysis — Enterprise HRMS |
| **Product / Project** | SERV Workforce Management & Attendance Reporting |
| **Version** | 1.0 |
| **Status** | Draft |
| **Date** | 2026-09-16 |
| **Author** | Product Engineering |

---

## 2. Executive Summary

This document defines the application scope for an **Enterprise HRMS Product Model** and maps it against the current capabilities of **SERV** (Flutter + Firebase Functions workforce application). It identifies functional gaps, integration needs, and compliance requirements that must be addressed to position SERV as a full-featured enterprise HRMS.

### Current State (SERV)
SERV supports employee-facing and admin-facing workflows for attendance, leave, shift management, task assignment, rewards, office tracking, and reporting. It is a strong operational workforce tool but is not yet a complete HRMS for enterprise use.

### Target State (Enterprise HRMS)
An enterprise HRMS must cover the full employee lifecycle — recruitment, onboarding, core HR, payroll, benefits, time and attendance, performance, learning, engagement, offboarding, and analytics — while supporting role-based access, multi-entity/location, audit trails, integrations, and regulatory compliance.

---

## 3. Enterprise HRMS Product Scope

### 3.1 Core HR Foundations

| Module | Scope |
|--------|-------|
| **Employee Records** | Centralized employee profiles, org structure, job history, contracts, documents, contact info, emergency contacts. |
| **Organization Management** | Departments, divisions, locations, cost centers, reporting hierarchy, matrix management. |
| **Role-Based Access Control (RBAC)** | Granular roles: Employee, Manager, HR, Admin, Payroll, Finance, Auditor, Super Admin. |
| **Self-Service Portal** | Employees and managers can update profiles, view payslips, request leave, approve workflows. |
| **Document Management** | Digital contracts, offer letters, tax forms, certificates, policy acknowledgments. |

### 3.2 Talent Acquisition & Onboarding

| Module | Scope |
|--------|-------|
| **Recruitment / ATS** | Job requisitions, candidate pipeline, interviews, offers. |
| **Onboarding** | Task checklists, document collection, welcome workflows, system provisioning. |
| **Offboarding** | Exit interviews, asset recovery, access revocation, final settlements. |

### 3.3 Time, Attendance & Workforce Management

| Module | Scope |
|--------|-------|
| **Time & Attendance** | Clock-in/out, geo-fencing, biometric integration, timesheets, overtime rules. |
| **Shift & Roster** | Shift patterns, schedules, swaps, coverage rules, notifications. |
| **Leave & Absence** | Leave types, entitlements, accrual rules, approvals, carry-forward, holiday calendars. |

### 3.4 Compensation, Payroll & Benefits

| Module | Scope |
|--------|-------|
| **Payroll** | Salary structures, pay runs, deductions, statutory contributions, payslips, year-end tax forms. |
| **Benefits Administration** | Health insurance, retirement/pension, perks, enrollment windows, beneficiary records. |
| **Expense Claims** | Submission, approval, reimbursement, policy limits, receipt capture. |

### 3.5 Talent Management

| Module | Scope |
|--------|-------|
| **Performance Management** | Goal setting, OKRs/KPIs, 360 reviews, calibration, feedback cycles. |
| **Learning & Development** | Training catalogs, course assignments, certifications, skills tracking. |
| **Succession Planning** | Talent pools, readiness ratings, career paths, successor tracking. |

### 3.6 Employee Engagement & Communication

| Module | Scope |
|--------|-------|
| **Employee Engagement** | Surveys (eNPS, pulse), recognition, rewards, announcements. |
| **Communication Hub** | Company directory, org-wide announcements, team messaging integration. |

### 3.7 Workforce Analytics & Reporting

| Module | Scope |
|--------|-------|
| **HR Analytics** | Headcount, attrition, hiring funnel, attendance trends, performance distribution. |
| **Compliance Reporting** | EEO, labor law, audit logs, data retention reports. |
| **Custom Reports & Dashboards** | Configurable dashboards, scheduled reports, export (PDF, Excel, CSV). |

### 3.8 Integrations & Platform

| Module | Scope |
|--------|-------|
| **Identity & Access** | SSO (SAML / OIDC), MFA, Active Directory / Entra ID sync. |
| **Finance / Accounting** | GL mapping, payroll journal entries, accounting system integrations. |
| **Calendar & Communication** | Outlook / Google Calendar, Slack / Teams notifications. |
| **Biometric / Hardware** | Access control, fingerprint/face recognition clocking devices. |
| **Third-Party APIs** | Background checks, learning platforms, benefits providers. |

### 3.9 Compliance, Security & Data Privacy

| Module | Scope |
|--------|-------|
| **Compliance** | Local labor law adherence, minimum wage, working-hour limits, leave mandates. |
| **Data Privacy** | GDPR / CCPA / regional privacy laws, consent management, data subject requests. |
| **Security** | Encryption at rest and in transit, audit trails, role-based data masking. |

---

## 4. Current State Mapping — SERV

| Enterprise HRMS Module | Current SERV Capability | Coverage |
|------------------------|------------------------|----------|
| Employee Records | Basic employee profile and role-based login. | Partial |
| Organization Management | Admin/user flows, limited org structure. | Partial |
| RBAC | Employee and Admin roles exist. | Partial |
| Self-Service | Employee and admin mobile/web flows. | Partial |
| Recruitment / ATS | Not present. | Not Covered |
| Onboarding / Offboarding | Not present. | Not Covered |
| Time & Attendance | Clock-in/out, geo-fenced office tracking, live employee details. | Strong |
| Shift & Roster | Shift management, task assignment. | Strong |
| Leave & Absence | Leave request and approval. | Moderate |
| Payroll | Not present. | Not Covered |
| Benefits | Rewards and feedback only. | Partial |
| Expense Claims | Not present. | Not Covered |
| Performance Management | Task management, task assignment history. | Partial |
| Learning & Development | Not present. | Not Covered |
| Succession Planning | Not present. | Not Covered |
| Engagement / Communication | Rewards, feedback, events, reports. | Partial |
| HR Analytics | Reports and uploads. | Partial |
| Compliance / Security | Firebase security model; formal compliance controls are not evident. | Partial |
| Integrations | Firebase ecosystem; no SSO/accounting/biometric integrations visible. | Partial |

---

## 5. Gap Analysis Matrix

### 5.1 Functional Gaps

| # | Gap Area | Current State | Target State | Impact | Priority |
|---|----------|---------------|--------------|--------|----------|
| 1 | **Core HR Employee Records** | Basic profile; no job history, contracts, or document vault. | Full employee master with history, contracts, documents, org hierarchy. | High — foundational for any HRMS. | **P1** |
| 2 | **Recruitment / ATS** | No recruitment functionality. | End-to-end hiring pipeline from requisition to offer. | High — blocks talent acquisition. | **P1** |
| 3 | **Onboarding & Offboarding** | No lifecycle workflows. | Structured onboarding/offboarding checklists and automation. | High — compliance and experience risk. | **P1** |
| 4 | **Payroll** | No payroll engine. | Full payroll with statutory compliance, payslips, and tax forms. | Critical — enterprise blocker. | **P1** |
| 5 | **Benefits Administration** | Rewards only; no benefits enrollment or administration. | Benefits catalog, enrollment, dependents, and provider integrations. | High — compensation completeness. | **P2** |
| 6 | **Expense Management** | Not present. | Expense submission, approval, reimbursement, and policy enforcement. | Medium — operational efficiency. | **P2** |
| 7 | **Performance Management** | Tasks only; no goals or reviews. | Goal/OKR tracking, review cycles, 360 feedback, calibration. | High — talent management. | **P1** |
| 8 | **Learning & Development** | Not present. | Course catalog, assignments, certifications, skills matrix. | Medium — growth and retention. | **P2** |
| 9 | **Advanced Leave & Absence** | Basic request/approval. | Accrual engine, leave calendars, carry-forward, FMLA/region-specific leave. | Medium — compliance and accuracy. | **P2** |
| 10 | **Advanced Scheduling** | Shift management exists. | AI-assisted rostering, labor law rules, shift swap marketplace. | Medium — efficiency. | **P3** |
| 11 | **Succession & Career Planning** | Not present. | Talent pools, readiness levels, career path modeling. | Low-Medium — strategic HR. | **P3** |

### 5.2 Technical & Integration Gaps

| # | Gap Area | Current State | Target State | Impact | Priority |
|---|----------|---------------|--------------|--------|----------|
| 1 | **SSO / Identity Federation** | Firebase Authentication only. | SAML / OIDC SSO, AD/Entra ID sync, MFA enforcement. | High — enterprise security. | **P1** |
| 2 | **Financial System Integration** | No accounting integration. | Payroll GL mapping, journal entries, ERP sync. | High — payroll readiness. | **P1** |
| 3 | **Biometric / Hardware Clocking** | Geo-fenced mobile clock-in. | Biometric terminals, badge readers, kiosk clocking. | Medium — accuracy and fraud prevention. | **P2** |
| 4 | **Calendar & Communication Integrations** | In-app notifications only. | Outlook/Google Calendar, Slack/Teams, email/SMS gateways. | Medium — adoption. | **P2** |
| 5 | **Background Check / Verification APIs** | Not present. | Integration with verification providers. | Medium — hiring compliance. | **P2** |
| 6 | **Advanced Reporting / BI** | Basic reports and uploads. | Configurable dashboards, scheduled reports, data warehouse/BI export. | High — decision support. | **P1** |

### 5.3 Compliance & Security Gaps

| # | Gap Area | Current State | Target State | Impact | Priority |
|---|----------|---------------|--------------|--------|----------|
| 1 | **Audit Trails** | Firebase logs; limited application-level audit. | Immutable audit logs for all HR data changes and approvals. | High — compliance. | **P1** |
| 2 | **Data Privacy / GDPR** | Not formally addressed. | Consent management, DSR workflows, retention policies, privacy notices. | High — legal risk. | **P1** |
| 3 | **Data Residency** | Default Firebase regions. | Region-specific data storage for multi-country deployments. | Medium — global expansion. | **P2** |
| 4 | **Role-Based Data Masking** | Basic role separation. | Field-level data masking, segregation by country/entity/department. | High — privacy. | **P1** |
| 5 | **SOC 2 / ISO 27001 Alignment** | Not evident. | Security controls, policies, evidence for certifications. | Medium — enterprise trust. | **P2** |
| 6 | **Electronic Signatures** | Not present. | Legally binding e-signature for contracts, policies, and forms. | Medium — onboarding/offboarding. | **P2** |

### 5.4 Multi-Entity & Scalability Gaps

| # | Gap Area | Current State | Target State | Impact | Priority |
|---|----------|---------------|--------------|--------|----------|
| 1 | **Multi-Company / Multi-Legal Entity** | Single-tenant appearance. | Support multiple legal entities, currencies, and localizations. | High — enterprise selling. | **P1** |
| 2 | **Multi-Country / Localization** | Single-region support. | Localized languages, currencies, tax, and labor law rules. | High — global use. | **P2** |
| 3 | **Hierarchical Approval Workflows** | Simple approvals. | Configurable multi-level approval chains with delegation and escalations. | Medium — process maturity. | **P2** |
| 4 | **Tenancy / Isolation Model** | Firebase project-based. | Clear tenant isolation, white-label, and enterprise branding options. | Medium — scale. | **P2** |

---

## 6. Prioritized Roadmap

### Phase 1 — HRMS Foundation (0–3 months)
- Strengthen employee master records (job history, contracts, documents).
- Implement RBAC expansion and data masking.
- Add audit trails and basic GDPR/privacy controls.
- Improve reporting and dashboards.

### Phase 2 — Core HR & Talent (3–6 months)
- Recruitment / ATS lightweight module.
- Onboarding / offboarding workflows.
- Performance management (goals, reviews, feedback).
- Advanced leave accrual engine.

### Phase 3 — Compensation & Integrations (6–12 months)
- Payroll module or certified payroll integration partner.
- Benefits administration.
- SSO / SAML / OIDC.
- Finance/ERP integrations.

### Phase 4 — Scale & Intelligence (12+ months)
- Multi-entity and multi-country support.
- Learning & development.
- Advanced workforce analytics / predictive insights.
- Mobile/web parity and white-label enterprise packaging.

---

## 7. Risk & Dependencies

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Payroll Complexity** | Payroll laws vary by country and change frequently. | Partner with a payroll engine or restrict initial rollout to regions with simple rules. |
| **Compliance Exposure** | Missing GDPR/labor law controls creates legal risk. | Engage legal/compliance review early; implement audit trails and DSR workflows. |
| **Integration Burden** | Enterprise buyers expect SSO, ERP, and calendar integrations. | Build a plugin/integration framework; prioritize high-demand connectors. |
| **Data Model Rework** | Current model may not support multi-entity or historical records. | Design the core HR data model before adding modules. |
| **Firebase Limitations** | Complex reporting and multi-tenancy can be challenging on Firestore. | Evaluate BigQuery, separate tenant schemas, or read replicas for analytics. |

---

## 8. Recommendations

1. **Reposition SERV as a "Workforce Operations + Core HR" platform** rather than a full HRMS initially, then expand into payroll and talent.
2. **Build a centralized Employee Master** first; every other module depends on it.
3. **Adopt a modular architecture** so enterprise customers can enable only the modules they need.
4. **Prioritize compliance and security** (RBAC, audit logs, data privacy) before selling to regulated or large enterprises.
5. **Evaluate payroll strategy** — build vs. partner — early, as it is the biggest enterprise blocker.
6. **Introduce formal product documentation, API contracts, and a public integration roadmap** to support enterprise sales and solution architects.

---

## 9. Approval & Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Engineering Lead | | | |
| Compliance / Legal | | | |
| Executive Sponsor | | | |

---

*End of Document*
