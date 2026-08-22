import { Request, Response } from "express";
import { validateOnboarding } from "../validators/onboarding.validator";
import {
  createOnboarding,
  getAllOnboardings,
  getOnboardingById,
  resolveDocumentStoragePath,
  updateOnboardingStatus,
  uploadFileToFirebase,
} from "../services/onboarding.service";
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

    const employeeId = req.body.employeeId;

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
    const { search, status, department, branch } = req.query;
    
    // Log the query parameters for debugging
    console.log('Query params:', { search, status, department, branch });
    
    const data = await getAllOnboardings({
      search: search as string,
      status: status as string,
      department: department as string,
      branch: branch as string,
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

export const changeOnboardingStatus = async (req: Request, res: Response) => {
  try {
    const { status } = req.body;

    if (!["pending", "approved", "rejected", "completed"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status",
      });
    }

    await updateOnboardingStatus(req.params.id as string, status);

    return res.status(200).json({
      success: true,
      message: "Onboarding status updated successfully",
    });
  } catch (error) {
    console.error("Update onboarding status error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};