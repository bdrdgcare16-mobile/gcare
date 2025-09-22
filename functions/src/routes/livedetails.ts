import { Router } from "express";
import { listLiveDetails, getLiveDetail } from "../controllers/livedetails.controller";

const router = Router();

router.get("/", listLiveDetails);       // GET /api/livedetails?date=YYYY-MM-DD
router.get("/:empid", getLiveDetail);   // GET /api/livedetails/:empid?date=YYYY-MM-DD

export default router;
