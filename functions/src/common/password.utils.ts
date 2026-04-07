export const isBcryptHash = (s = ""): boolean => {
  return /^\$2[aby]\$/.test(String(s));
};