export interface OnboardingQuery {
  search?: string;
  status?: string;
  department?: string;
  branch?: string;
}

export interface OnboardingDocument {
  resume?: string;
  offerLetter?: string;
  aadhaarCard?: string;
  panCard?: string;
  bankProof?: string;
  degreeCertificate?: string;
  passportPhoto?: string;
  experienceCertificate?: string;
  relievingLetter?: string;
}

export interface PersonalDetails {
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
}

export interface CompanyDetails {
  companyName: string;
  branchLocation: string;
  dateOfJoining: string;
  department: string;
  designation: string;
  officialEmail?: string;
  employeeId: string;
  shiftTime: string;
  workMode: string;
  employeeType: string;
  experienceLevel: string;
  yearsOfExperience?: number;
  reportingManager: string;
}

export interface BankDetails {
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
}

export interface EmployeeOnboarding {
  id?: string;
  personalDetails: PersonalDetails;
  companyDetails: CompanyDetails;
  bankDetails: BankDetails;
  documents: OnboardingDocument;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
  createdAt: Date;
  updatedAt?: Date;
}
