import { Request } from "express";

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const mobileRegex = /^[0-9]{10}$/;
const pincodeRegex = /^[0-9]{6}$/;
const ifscRegex = /^[A-Z]{4}0[A-Z0-9]{6}$/;
const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
const aadhaarRegex = /^[0-9]{12}$/;
const accountRegex = /^[0-9]{9,18}$/;

export const validateOnboarding = (req: Request): string[] => {
  const errors: string[] = [];
  const body = req.body;

  const requiredFields = [
    "fullName",
    "gender",
    "dob",
    "personalEmail",
    "mobileCountryCode",
    "mobileNumber",
    "address",
    "city",
    "state",
    "pincode",
    "country",
    "permanentAddress",
    "emergencyContactName",
    "emergencyCountryCode",
    "emergencyContactNumber",

    "companyName",
    "branchLocation",
    "dateOfJoining",
    "department",
    "designation",
    "officialEmail",
    "employeeId",
    "shiftTime",
    "workMode",
    "employeeType",
    "experienceLevel",
    "reportingManager",

    "bankName",
    "accountHolderName",
    "accountNumber",
    "ifscCode",
    "panNumber",
    "aadhaarNumber",
    "basicSalary",
    "hra",
    "allowances",
    "grossSalary",
    "netSalary",
  ];

  requiredFields.forEach((field) => {
    if (!body[field] || body[field].toString().trim() === "") {
      errors.push(`${field} is required`);
    }
  });

  if (body.personalEmail && !emailRegex.test(body.personalEmail)) {
    errors.push("Invalid personal email format");
  }

  if (body.officialEmail && !emailRegex.test(body.officialEmail)) {
    errors.push("Invalid official email format");
  }

  if (body.personalEmail && !body.personalEmail.endsWith("@gmail.com")) {
    errors.push("Personal email must be a Gmail address");
  }

  if (body.mobileNumber && !mobileRegex.test(body.mobileNumber)) {
    errors.push("Mobile number must be exactly 10 digits");
  }

  if (
    body.emergencyContactNumber &&
    !mobileRegex.test(body.emergencyContactNumber)
  ) {
    errors.push("Emergency contact number must be exactly 10 digits");
  }

  if (body.mobileNumber === body.emergencyContactNumber) {
    errors.push("Emergency contact number should not match mobile number");
  }

  if (body.pincode && !pincodeRegex.test(body.pincode)) {
    errors.push("Pincode must be exactly 6 digits");
  }

  if (body.accountNumber && !accountRegex.test(body.accountNumber)) {
    errors.push("Account number must be between 9 and 18 digits");
  }

  if (body.ifscCode && !ifscRegex.test(body.ifscCode.toUpperCase())) {
    errors.push("Invalid IFSC code");
  }

  if (body.panNumber && !panRegex.test(body.panNumber.toUpperCase())) {
    errors.push("Invalid PAN number");
  }

  if (body.aadhaarNumber && !aadhaarRegex.test(body.aadhaarNumber)) {
    errors.push("Aadhaar number must be exactly 12 digits");
  }

  if (
    body.experienceLevel === "Experienced" &&
    (!body.yearsOfExperience || Number(body.yearsOfExperience) <= 0)
  ) {
    errors.push("Years of experience is required for experienced employees");
  }

  return errors;
};