/**
 * Script one-shot para habilitar TOTP MFA no projeto Firebase.
 * Execute uma vez: npx ts-node backend/src/scripts/enableTotp.ts
 */
import '../firebaseAdmin';
import { getAuth } from 'firebase-admin/auth';

async function enableTotp() {
  try {
    await getAuth().projectConfigManager().updateProjectConfig({
      multiFactorConfig: {
        state: 'ENABLED',
        providerConfigs: [{
          state: "ENABLED",
          totpProviderConfig: {
            adjacentIntervals: 5
          }
        }]
      }
    });
    console.log('✅ TOTP MFA habilitado com sucesso no projeto Firebase!');
  } catch (error) {
    console.error('❌ Erro ao habilitar TOTP MFA:', error);
  }
  process.exit(0);
}

enableTotp();
