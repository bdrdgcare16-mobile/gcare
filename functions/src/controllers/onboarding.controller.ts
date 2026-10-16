import * as fs from "fs";
import * as path from "path";
import { Request, Response } from "express";
import { validateOnboarding } from "../validators/onboarding.validator";
import { encryptCredential } from "../services/onboardingCredential.service";
import {
  createOnboarding,
  getAllOnboardings,
  getOnboardingById,
  getOnboardingByEmpId,
  getOnboardingDoc,
  resolveDevDocumentFile,
  resolveDocumentStoragePath,
  updateOnboardingStatus,
  uploadFileToFirebase,
} from "../services/onboarding.service";
import {
  provisionEmployeeFromOnboarding,
  ProvisioningError,
} from "../services/employeeProvisioning.service";
import { EmployeeOnboarding } from "../types/onboarding.types";

export const createEmployeeOnboarding = async (
  req: Request,
  res: Response
) => {
  console.log('[onboarding-upload] controller reached');
  try {
    const authenticatedCompanyId = String(req.user?.companyId ?? '').trim();
    if (!authenticatedCompanyId) {
      return res.status(403).json({
        success: false,
        message: 'Company context is required',
      });
    }

    const errors = validateOnboarding(req);

    if (errors.length > 0) {
      console.log('[onboarding-controller] Validation failed with errors:', errors);
      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors,
      });
    }

    const files = req.files as {
      [fieldname: string]: Express.Multer.File[];
    };

    const employeeId = String(req.body.employeeId ?? '').trim();

    // Duplicate guard: the same employeeId within this company must not
    // produce a second onboarding record while one is already pending,
    // approved or completed. A rejected request may be resubmitted.
    const existing = await getOnboardingByEmpId(employeeId);
    if (
      existing &&
      existing.companyDetails?.companyId === authenticatedCompanyId &&
      String(existing.status ?? "pending") !== "rejected"
    ) {
      return res.status(409).json({
        success: false,
        message:
          "An onboarding request for this employee ID already exists",
      });
    }

    const documents: Record<string, string> = {};

    if (files) {
      for (const fieldName of Object.keys(files)) {
        const file = files[fieldName][0];
        documents[fieldName] = await uploadFileToFirebase(
          file,
          employeeId,
          fieldName
        );
      }
    }

    const onboardingData: EmployeeOnboarding & {
      companyDetails: EmployeeOnboarding['companyDetails'] & { companyId: string };
    } = {
      personalDetails: {
        fullName: req.body.fullName,
        gender: req.body.gender,
        dob: req.body.dob,
        personalEmail: req.body.personalEmail,
        mobileCountryCode: req.body.mobileCountryCode,
        mobileNumber: req.body.mobileNumber,
        address: req.body.address,
        city: req.body.city,
        state: req.body.state,
        pincode: req.body.pincode,
        country: req.body.country,
        permanentAddress: req.body.permanentAddress,
        emergencyContactName: req.body.emergencyContactName,
        emergencyCountryCode: req.body.emergencyCountryCode,
        emergencyContactNumber: req.body.emergencyContactNumber,
      },

      companyDetails: {
        companyId: authenticatedCompanyId,
        companyName: req.body.companyName,
        branchLocation: req.body.branchLocation,
        dateOfJoining: req.body.dateOfJoining,
        department: req.body.department,
        designation: req.body.designation,
        officialEmail: req.body.officialEmail,
        employeeId: req.body.employeeId,
        shiftTime: req.body.shiftTime,
        shiftId: String(req.body.shiftId ?? '').trim() || undefined,
        workMode: req.body.workMode,
        employeeType: req.body.employeeType,
        experienceLevel: req.body.experienceLevel,
        ...(req.body.experienceLevel === "Experienced" && {
          yearsOfExperience: Number(req.body.yearsOfExperience),
        }),
        reportingManager: req.body.reportingManager,
      },

      bankDetails: {
        bankName: req.body.bankName,
        accountHolderName: req.body.accountHolderName,
        accountNumber: req.body.accountNumber,
        ifscCode: req.body.ifscCode.toUpperCase(),
        panNumber: req.body.panNumber.toUpperCase(),
        aadhaarNumber: req.body.aadhaarNumber,
        ...(req.body.pfNumber && { pfNumber: req.body.pfNumber }),
        ...(req.body.esiNumber && { esiNumber: req.body.esiNumber }),
        basicSalary: Number(req.body.basicSalary),
        hra: req.body.hra ? Number(req.body.hra) : 0,
        allowances: req.body.allowances ? Number(req.body.allowances) : 0,
        grossSalary: Number(req.body.grossSalary),
        netSalary: Number(req.body.netSalary),
      },

      documents,
      // HR-supplied employee password, AES-256-GCM encrypted at rest —
      // decrypted only during approval-time provisioning (and Auth
      // identity repair). Never serialized back to clients — read paths
      // scrub this field.
      initialPasswordEnc: encryptCredential(String(req.body.password)),
      status: "pending",
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const id = await createOnboarding(onboardingData);

    return res.status(201).json({
      success: true,
      message: "Employee onboarding submitted successfully",
      id,
    });
  } catch (error) {
    console.error("Create onboarding error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

export const getEmployeeOnboardings = async (req: Request, res: Response) => {
  try {
    const companyId = String(req.user?.companyId ?? '').trim();
    if (!companyId) {
      return res.status(403).json({
        success: false,
        message: 'Company context is required',
      });
    }

    const { search, status, department, branch } = req.query;

    // Log the query parameters for debugging
    console.log('Query params:', { search, status, department, branch });

    const data = await getAllOnboardings({
      search: search as string,
      status: status as string,
      department: department as string,
      branch: branch as string,
      companyId,
    });

    console.log('Fetched onboardings:', data.length);
    
    return res.status(200).json({
      success: true,
      data,
      count: data.length,
    });
  } catch (error) {
    console.error("Get onboarding error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

export const getEmployeeOnboardingById = async (
  req: Request,
  res: Response
) => {
  try {
    const data = await getOnboardingById(req.params.id as string);

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Onboarding record not found",
      });
    }

    const companyId = String(req.user?.companyId ?? '').trim();
    if (!companyId || data.companyDetails?.companyId !== companyId) {
      return res.status(403).json({
        success: false,
        message: "Access denied: companyId mismatch",
      });
    }

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error("Get onboarding by id error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

// Resolves a Firebase Storage object path (as stored in the onboarding
// document record) to a short-lived signed download URL. Legacy records
// that already contain a full http(s) URL should never reach this endpoint
// (the client opens those directly), but if one does, the underlying
// normalization in the service layer will still handle it safely.
export const getOnboardingByEmployeeId = async (
  req: Request,
  res: Response
) => {
  try {
    const empid = String(req.params.empid ?? '').trim();
    if (!empid) {
      return res.status(400).json({
        success: false,
        message: 'Employee ID is required',
      });
    }

    const data = await getOnboardingByEmpId(empid);

    if (!data) {
      return res.status(404).json({
        success: false,
        message: 'Onboarding record not found for this employee',
      });
    }

    // Tenant scoping — the record carries bank details and must never
    // leak across companies.
    const companyId = String(req.user?.companyId ?? '').trim();
    if (!companyId || data.companyDetails?.companyId !== companyId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: companyId mismatch',
      });
    }

    // Return only the fields needed for payslip – exclude documents/signed URLs
    const personalDetails = data.personalDetails ?? {};
    const companyDetails = data.companyDetails ?? {};
    const bankDetails = data.bankDetails ?? {};

    return res.status(200).json({
      success: true,
      data: {
        id: data.id,
        personalDetails: {
          fullName: personalDetails.fullName ?? '',
        },
        companyDetails: {
          companyName: companyDetails.companyName ?? '',
          branchLocation: companyDetails.branchLocation ?? '',
          dateOfJoining: companyDetails.dateOfJoining ?? '',
          department: companyDetails.department ?? '',
          designation: companyDetails.designation ?? '',
          employeeId: companyDetails.employeeId ?? '',
        },
        bankDetails: {
          bankName: bankDetails.bankName ?? '',
          accountNumber: bankDetails.accountNumber ?? '',
          ifscCode: bankDetails.ifscCode ?? '',
          panNumber: bankDetails.panNumber ?? '',
          pfNumber: bankDetails.pfNumber ?? '',
          esiNumber: bankDetails.esiNumber ?? '',
          basicSalary: bankDetails.basicSalary ?? 0,
          hra: bankDetails.hra ?? 0,
          allowances: bankDetails.allowances ?? 0,
          grossSalary: bankDetails.grossSalary ?? 0,
          netSalary: bankDetails.netSalary ?? 0,
        },
        status: data.status ?? 'pending',
      },
    });
  } catch (error) {
    console.error("Get onboarding by empid error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

export const resolveOnboardingDocumentUrl = async (
  req: Request,
  res: Response
) => {
  try {
    const path = String(req.query.path ?? "").trim();

    if (!path) {
      return res.status(400).json({
        success: false,
        message: "Query parameter 'path' is required",
      });
    }

    // Tenant scoping: document paths are stored as
    // onboarding-dev/{employeeId}/... — verify a same-company onboarding
    // record exists for that employeeId before minting a signed URL.
    const companyId = String(req.user?.companyId ?? '').trim();
    const match = path.match(/^onboarding-dev\/([^/]+)\//);
    const docEmpid = match ? match[1] : '';
    const owner = docEmpid ? await getOnboardingByEmpId(docEmpid) : null;
    if (!companyId || !owner || owner.companyDetails?.companyId !== companyId) {
      return res.status(403).json({
        success: false,
        message: "Access denied: companyId mismatch",
      });
    }

    const url = await resolveDocumentStoragePath(path);

    return res.status(200).json({
      success: true,
      url,
    });
  } catch (error) {
    console.error("Resolve onboarding document URL error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to resolve document URL",
    });
  }
};

/**
 * DEV only — serves an emulator-local onboarding document when presented
 * with a valid HMAC-signed URL minted by the service (same bearer-token
 * trust model as a GCS signed URL). Registered only under the emulator.
 */
export const serveDevOnboardingFile = async (req: Request, res: Response) => {
  const storagePath = String(req.query.path ?? "");
  const expires = Number(req.query.e ?? 0);
  const signature = String(req.query.sig ?? "");

  const result = resolveDevDocumentFile(storagePath, expires, signature);
  if ("error" in result) {
    const status = result.error === "Not found" ? 404 : 403;
    res.status(status).json({ success: false, message: result.error });
    return;
  }

  const ext = path.extname(result.absolutePath).toLowerCase();
  const types: Record<string, string> = {
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
  };
  res.type(types[ext] ?? "application/octet-stream");

  const stream = fs.createReadStream(result.absolutePath);
  stream.on("error", () => {
    if (!res.headersSent) {
      res.status(404).json({ success: false, message: "Not found" });
    }
  });
  stream.pipe(res);
};

export const changeOnboardingStatus = async (req: Request, res: Response) => {
  try {
    const { status } = req.body;

    if (!["pending", "approved", "rejected", "completed"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status",
      });
    }

    const companyId = String(req.user?.companyId ?? '').trim();
    if (!companyId) {
      return res.status(403).json({
        success: false,
        message: 'Company context is required',
      });
    }

    const doc = await getOnboardingDoc(req.params.id as string);
    if (!doc) {
      return res.status(404).json({
        success: false,
        message: 'Onboarding record not found',
      });
    }

    if (doc.companyDetails?.companyId !== companyId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: companyId mismatch',
      });
    }

    // Approval triggers V2 provisioning — the employee master record,
    // login account and Firebase identity are created only here, never
    // at HR submission time. Status flips to 'approved' inside the
    // provisioning batch so a failure keeps the request pending and
    // safely retryable.
    if (status === 'approved') {
      const actorId = String((req as any).user?.userId ?? '');
      const result = await provisionEmployeeFromOnboarding(
        req.params.id as string,
        doc,
        companyId,
        actorId
      );

      return res.status(200).json({
        success: true,
        message: result.alreadyProvisioned
          ? 'Onboarding already approved'
          : 'Onboarding approved and employee account created',
        data: {
          status: 'approved',
          employeeDocId: result.employeeDocId,
          userId: result.userId,
          firebaseUid: result.firebaseUid,
          // Credentials are never returned — the employee uses the
          // password HR assigned during onboarding submission.
        },
      });
    }

    await updateOnboardingStatus(req.params.id as string, status);

    return res.status(200).json({
      success: true,
      message: "Onboarding status updated successfully",
    });
  } catch (error) {
    if (error instanceof ProvisioningError) {
      return res.status(error.status).json({
        success: false,
        message: error.message,
        code: error.code,
      });
    }
    console.error("Update onboarding status error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};