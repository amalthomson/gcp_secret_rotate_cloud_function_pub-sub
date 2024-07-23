"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateSecret = void 0;
const secret_manager_1 = require("@google-cloud/secret-manager");
const client = new secret_manager_1.SecretManagerServiceClient();
const rotateSecret = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b;
    const projectId = 'static-website-hosting-429208';
    const secretId = 'secret-creation-rotation';
    const secretName = `projects/${projectId}/secrets/${secretId}`;
    try {
        // Access the latest version of the secret
        const [version] = yield client.accessSecretVersion({
            name: `${secretName}/versions/latest`,
        });
        const payload = (_b = (_a = version.payload) === null || _a === void 0 ? void 0 : _a.data) === null || _b === void 0 ? void 0 : _b.toString();
        const previousVersionName = version.name;
        // Rotate the secret (create a new version)
        const [newVersion] = yield client.addSecretVersion({
            parent: secretName,
            payload: {
                data: Buffer.from('newly-rotated-secret-value'),
            },
        });
        // Destroy the previous version of the secret
        yield client.destroySecretVersion({
            name: previousVersionName,
        });
        console.log(`Created new secret version: ${newVersion.name}`);
        res.status(200).send(`Created new secret version: ${newVersion.name}`);
    }
    catch (error) {
        console.error(`Failed to rotate secret: ${error}`);
        res.status(500).send(`Failed to rotate secret: ${error}`);
    }
});
exports.rotateSecret = rotateSecret;
