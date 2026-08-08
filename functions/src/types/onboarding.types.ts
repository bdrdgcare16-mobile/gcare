export interface EmployeeOnboarding {
  personalDetails: {
    fullName: string;
    gender: string;
    dob: string;
    personalEmail: string;
    mobileCountryCode: string;
    mobileNumber: string;
    address: string;
    city: string;
    state: string;
    pincode: string;
    country: string;
    permanentAddress: string;
    emergencyContactName: string;
    emergencyCountryCode: string;
    emergencyContactNumber: string;
  };

  companyDetails: {
    companyName: string;
    branchLocation: string;
    dateOfJoining: string;
    department: string;
    designation: string;
    officialEmail: string;
    employeeId: string;
    shiftTime: string;
    workMode: string;
    employeeType: string;
    experienceLevel: string;
    yearsOfExperience?: number;
    reportingManager: string;
  };

  bankDetails: {
    bankName: string;
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
    panNumber: string;
    aadhaarNumber: string;
    pfNumber?: string;
    esiNumber?: string;
    basicSalary: number;
    hra?: number;
    allowances?: number;
    grossSalary: number;
    netSalary: number;
  };

  documents: {
    resume?: string;
    offerLetter?: string;
    aadhaarCard?: string;
    panCard?: string;
    bankProof?: string;
    degreeCertificate?: string;
    passportPhoto?: string;
    experienceCertificate?: string;
    relievingLetter?: string;
  };

  status: "pending" | "approved" | "rejected";
  createdAt: Date;
  updatedAt: Date;
}