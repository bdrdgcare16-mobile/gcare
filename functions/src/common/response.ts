import { Response } from "express";

export const successResponse = (
  res: Response,
  data: any,
  message: string,
  statusCode = 200
) => {
  return res.status(statusCode).json({
    message,
    ...(data || {}),
  });
};

export const errorResponse = (
  res: Response,
  message: string,
  statusCode = 500
) => {
  return res.status(statusCode).json({
    error: message,
  });
};