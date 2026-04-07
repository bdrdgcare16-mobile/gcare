export const isEmpty = (value: any): boolean => {
  if (value === undefined || value === null || value === "") {
    return true;
  }
  return false;
};

export const checkRequired = (
  body: any,
  fields: string[]
): string[] => {
  const missing: string[] = [];

  for (const field of fields) {
    if (isEmpty(body[field])) {
      missing.push(field);
    }
  }

  return missing;
};