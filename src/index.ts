import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

export const rotateSecret = async (req: any, res: any) => {
  const projectId = 'static-website-hosting-429208';
  const secretId = 'secret-creation-rotation';
  const secretName = `projects/${projectId}/secrets/${secretId}`;

  try {
    // Access the latest version of the secret
    const [version] = await client.accessSecretVersion({
      name: `${secretName}/versions/latest`,
    });
    const payload = version.payload?.data?.toString();
    const previousVersionName = version.name;

    // Rotate the secret (create a new version)
    const [newVersion] = await client.addSecretVersion({
      parent: secretName,
      payload: {
        data: Buffer.from('newly-rotated-secret-value'),
      },
    });

    // Destroy the previous version of the secret
    await client.destroySecretVersion({
      name: previousVersionName,
    });

    console.log(`Created new secret version: ${newVersion.name}`);
    res.status(200).send(`Created new secret version: ${newVersion.name}`);
  } catch (error) {
    console.error(`Failed to rotate secret: ${error}`);
    res.status(500).send(`Failed to rotate secret: ${error}`);
  }
};
