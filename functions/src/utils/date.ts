export const getCurrentTime = () => {
  return new Date().toISOString();
};

export const getTodayDate = () => {
  return new Date().toISOString().split("T")[0];
};