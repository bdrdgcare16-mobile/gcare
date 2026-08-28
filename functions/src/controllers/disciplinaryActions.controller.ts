// functions/src/controllers/disciplinaryActions.controller.ts
import { Request, Response } from 'express';
import {
  validateDisciplinaryAction,
  validateRejectDisciplinaryAction,
} from '../validators/disciplinaryActions.validator';
import {
  createDisciplinaryAction,
  getDisciplinaryActions,
  getDisciplinaryActionById,
  updateDisciplinaryAction,
  resubmitDisciplinaryAction,
  approveDisciplinaryAction,
  rejectDisciplinaryAction,
  resolveEvidenceUrl,
} from '../services/disciplinaryActions.service';
import { DISCIPLINARY_STATUS } from '../constants/disciplinary';

const normalizeStatus = (status: any): string | undefined => {
  if (!status) return undefined;
  const s = String(status).trim().toLowerCase();
  if (Object.values(DISCIPLINARY_STATUS).includes(s as any)) return s;
  return undefined;
};

const isSuperAdmin = (role?: string): boolean =>
  String(role).toLowerCase() === 'super_admin';

const isAdmin = (role?: string): boolean =>
  String(role).toLowerCase() === 'admin';

const isEmployee = (role?: string): boolean =>
  String(role).toLowerCase() === 'employee';

const authorizedDetail = async (
  req: Request,
  id: string
): Promise<{ data: any; status: number; message?: string }> => {
  const data = await getDisciplinaryActionById(id);
  if (!data) {
    return { data: null, status: 404, message: 'Disciplinary action not found' };
  }

  const user = req.user as {
    userId: string;
    role: string;
    companyId?: string | null;
  };

  if (isSuperAdmin(user.role)) {
    return { data, status: 200 };
  }

  if (isAdmin(user.role)) {
    if (data.companyId !== user.companyId) {
      return { data: null, status: 403, message: 'Access denied' };
    }
    return { data, status: 200 };
  }

  if (isEmployee(user.role)) {
    if (
      data.employeeUid === user.userId &&
      data.companyId === user.companyId &&
      data.status === DISCIPLINARY_STATUS.APPROVED
    ) {
      return { data, status: 200 };
    }
    return { data: null, status: 403, message: 'Access denied' };
  }

  return { data: null, status: 403, message: 'Access denied' };
};

export const createDisciplinaryActionController = async (
  req: Request,
  res: Response
) => {
  try {
    const errors = validateDisciplinaryAction(req);
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    const id = await createDisciplinaryAction({
      req,
      body: req.body,
      files: (req as any).files,
    });

    return res.status(201).json({
      success: true,
      message: 'Disciplinary action submitted for approval',
      id,
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Create error:', error?.message || error);
    return res.status(error?.message === 'Employee not found in this company' ? 404 : 500).json({
      success: false,
      message: error?.message || 'Internal server error',
    });
  }
};

export const getAdminDisciplinaryActionsController = async (
  req: Request,
  res: Response
) => {
  try {
    const user = req.user as { companyId?: string | null };
    if (!user.companyId) {
      return res.status(403).json({
        success: false,
        message: 'Company context is required',
      });
    }

    const status = normalizeStatus(req.query.status);
    const records = await getDisciplinaryActions({
      companyId: user.companyId,
      status,
    });

    return res.status(200).json({
      success: true,
      data: records,
      count: records.length,
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Admin list error:', error?.message || error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

export const getDisciplinaryActionByIdController = async (
  req: Request,
  res: Response
) => {
  try {
    const { data, status, message } = await authorizedDetail(req, req.params.id);

    if (!data) {
      return res.status(status).json({
        success: false,
        message: message || 'Not found',
      });
    }

    // Resolve evidence to a short-lived signed URL only when the accessor
    // has already passed authorization checks above.
    if (data.attachmentUrl) {
      try {
        data.attachmentUrl = await resolveEvidenceUrl(data.attachmentUrl);
      } catch (err) {
        console.error('[DisciplinaryAction] Evidence URL error:', err);
        data.attachmentUrl = null;
      }
    }

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Get by id error:', error?.message || error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

export const updateDisciplinaryActionController = async (
  req: Request,
  res: Response
) => {
  try {
    const errors = validateDisciplinaryAction(req);
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    await updateDisciplinaryAction({
      req,
      id: req.params.id,
      body: req.body,
      files: (req as any).files,
    });

    return res.status(200).json({
      success: true,
      message: 'Disciplinary action updated successfully',
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Update error:', error?.message || error);
    return res.status(error?.message === 'Disciplinary action not found' ? 404 : 500).json({
      success: false,
      message: error?.message || 'Internal server error',
    });
  }
};

export const resubmitDisciplinaryActionController = async (
  req: Request,
  res: Response
) => {
  try {
    const errors = validateDisciplinaryAction(req);
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    await resubmitDisciplinaryAction({
      req,
      id: req.params.id,
      body: req.body,
      files: (req as any).files,
    });

    return res.status(200).json({
      success: true,
      message: 'Disciplinary action resubmitted for approval',
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Resubmit error:', error?.message || error);
    return res.status(error?.message === 'Disciplinary action not found' ? 404 : 500).json({
      success: false,
      message: error?.message || 'Internal server error',
    });
  }
};

export const getSuperAdminDisciplinaryActionsController = async (
  req: Request,
  res: Response
) => {
  try {
    const status = normalizeStatus(req.query.status);
    const records = await getDisciplinaryActions({ status });

    return res.status(200).json({
      success: true,
      data: records,
      count: records.length,
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Super admin list error:', error?.message || error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

export const approveDisciplinaryActionController = async (
  req: Request,
  res: Response
) => {
  try {
    await approveDisciplinaryAction({ req, id: req.params.id });

    return res.status(200).json({
      success: true,
      message: 'Disciplinary action approved',
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Approve error:', error?.message || error);
    return res.status(error?.message === 'Disciplinary action not found' ? 404 : 500).json({
      success: false,
      message: error?.message || 'Internal server error',
    });
  }
};

export const rejectDisciplinaryActionController = async (
  req: Request,
  res: Response
) => {
  try {
    const errors = validateRejectDisciplinaryAction(req);
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    await rejectDisciplinaryAction({
      req,
      id: req.params.id,
      rejectionReason: req.body.rejectionReason,
    });

    return res.status(200).json({
      success: true,
      message: 'Disciplinary action rejected',
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Reject error:', error?.message || error);
    return res.status(error?.message === 'Disciplinary action not found' ? 404 : 500).json({
      success: false,
      message: error?.message || 'Internal server error',
    });
  }
};

export const getEmployeeDisciplinaryActionsController = async (
  req: Request,
  res: Response
) => {
  try {
    const user = req.user as {
      userId: string;
      companyId?: string | null;
    };

    if (!user.companyId) {
      return res.status(403).json({
        success: false,
        message: 'Company context is required',
      });
    }

    const records = await getDisciplinaryActions({
      employeeUid: user.userId,
      companyId: user.companyId,
      status: DISCIPLINARY_STATUS.APPROVED,
    });

    return res.status(200).json({
      success: true,
      data: records,
      count: records.length,
    });
  } catch (error: any) {
    console.error('[DisciplinaryAction] Employee list error:', error?.message || error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};
