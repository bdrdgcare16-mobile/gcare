export const pickEmpId = (obj: any): string | null => {
  const candidates = [obj?.empid, obj?.empId, obj?.employeeId];
  const v = candidates.find((x) => x != null && String(x).trim() !== '');
  return v != null ? String(v).trim() : null;
};