import { Request } from "express";



const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const mobileRegex = /^[0-9]{10}$/;

const pincodeRegex = /^[0-9]{6}$/;

const ifscRegex = /^[A-Z]{4}0[A-Z0-9]{6}$/;

const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]$/;

const aadhaarRegex = /^[0-9]{12}$/;

const accountRegex = /^[0-9]{9,18}$/;

const fullNameRegex = /^[a-zA-Z]+(?: [a-zA-Z]+)*$/;



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

    // Address is intentionally optional, but is still stored when provided.

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

    // hra and allowances are optional - controller handles empty values as 0

    "grossSalary",

    "netSalary",

  ];



  // DEBUG: Log received fields (excluding sensitive data)

  const receivedFields = Object.keys(body).filter(key => 

    !['password', 'aadhaarNumber', 'accountNumber', 'panNumber'].includes(key)

  );

  const missingFields: string[] = [];



  requiredFields.forEach((field) => {

    if (!body[field] || body[field].toString().trim() === "") {

      errors.push(`${field} is required`);

      missingFields.push(field);

    }

  });



  // Log validation debug info

  console.log('VALIDATION DEBUG:', {

    receivedFields,

    missingFields,

    totalReceived: receivedFields.length,

    totalRequired: requiredFields.length,

    errorsCount: errors.length

  });



  if (body.fullName && !fullNameRegex.test(body.fullName.toString().trim())) {

    errors.push("Full name must contain only letters and spaces");

  }



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



  // Required onboarding documents: these are expected as multipart file fields

  // from the same upload middleware used in onboarding.routes.ts. They are

  // enforced server-side as well as in the Flutter form.

  const files = (req as any).files as {

    [fieldname: string]: Express.Multer.File[] | undefined;

  } | undefined;



  const requiredDocuments = [

    "resume",

    "offerLetter",

    "aadhaarCard",

    "panCard",

  ];



  const uploadedFileFields = Object.keys(files || {});

  const missingDocuments: string[] = [];



  for (const doc of requiredDocuments) {

    const uploaded = files?.[doc];

    if (!uploaded || uploaded.length === 0) {

      errors.push(`${doc} is required`);

      missingDocuments.push(doc);

    }

  }



  // Log file validation debug info

  console.log('VALIDATION DEBUG FILES:', {

    uploadedFileFields,

    missingDocuments,

    totalUploaded: uploadedFileFields.length,

    totalRequiredDocs: requiredDocuments.length,

    fileErrorsCount: errors.length - (errors.length - missingDocuments.length)

  });



  return errors;

};