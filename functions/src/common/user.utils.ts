export const pickEmpId = (obj: any): string | null => {
  const v = obj?.empid ?? obj?.empId ?? obj?.employeeId ?? null;
  return v ? String(v).trim() : null;
};