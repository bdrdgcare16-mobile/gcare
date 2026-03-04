"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const plain = "Suja25@serv";
const hash = "$2a$10$7MGViJTEUD/pktpu/3fYX.eyjruM1aYzPW1YzymQG51uIl7vkMv1C";
async function check() {
    const ok = await bcryptjs_1.default.compare(plain, hash);
    console.log("Password match:", ok);
}
check();
//# sourceMappingURL=verify.js.map