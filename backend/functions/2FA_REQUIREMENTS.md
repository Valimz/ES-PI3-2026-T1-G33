<!--
Autor: Felipe Augusto dos Santos Silva
RA: 25003353
-->

# Requisitos e métodos para Verificação em Duas Etapas (2FA)

Este documento descreve os requisitos funcionais, de segurança e arquiteturais para implementar 2FA no projeto.

## Objetivo

Adicionar uma camada adicional de autenticação para proteger contas de usuários contra comprometimento de credenciais. Suportar múltiplos métodos (preferencialmente TOTP com fallback por SMS/e-mail) e fornecer códigos de recuperação.

## Escopo

- Enrolamento (ativação) do 2FA por usuário
- Verificação no login após credenciais válidas
- Fallbacks: SMS e e-mail (opcional, custos associados)
- Geração e gerenciamento de códigos de recuperação (backup codes)
- APIs backend, persistência segura e UI mínima

## Modelo de ameaça (resumo)

- Ataque por força bruta em códigos 2FA
- Interceptação de SMS (SIM swap)
- Comprometimento da base de dados (secrets não cifrados)
- Reutilização/roubo de códigos de recuperação

## Requisitos de segurança essenciais

- Segredos TOTP (`2fa_secret`) devem ser cifrados em repouso (AES-256 com chave gerenciada por variáveis de ambiente ou KMS).
- Códigos de recuperação devem ser armazenados apenas como hashes (bcrypt/argon2) e exibidos apenas uma vez no momento da geração.
- Limitar tentativas (rate limiting) e aplicar bloqueio temporário após N tentativas falhas.
- Registrar eventos importantes (enrolamento, ativação, falhas de verificação, regen de backup codes) para auditoria.
- Usar HTTPS/TLS em todas as comunicações.

## Métodos suportados (prós/contras)

- TOTP (RFC 6238)
  - Prós: sem custo, interoperável com apps (Google Authenticator, Authy), robusto.
  - Contras: depende do relógio do dispositivo; usuário precisa instalar app.
  - Configurações recomendadas: 6 dígitos, 30s step, permitir janela de +-1 step para tolerância.

- SMS
  - Prós: simples para usuário, sem app necessário.
  - Contras: custos por mensagem, vulnerável a SIM swap e interceptação.

- E-mail
  - Prós: sem custo do provedor externo em muitos casos; fácil implementação.
  - Contras: dependente da segurança do e-mail do usuário; atrasos possíveis.

- Push (FCM/APNs)
  - Prós: UX superior (aprove/reprovar), resistente a erros de digitação.
  - Contras: implementação mais complexa; exige infraestrutura de push (Firebase Cloud Messaging, APNs).

Recomendação inicial: Implementar TOTP como principal método (recomendado para segurança) e SMS/e-mail como fallback opcional.

## Fluxos de UX (resumo)

1. Enrolamento (ativação)
   - Usuário solicita ativar 2FA.
   - Backend gera `2fa_secret` (base32) e códigos de recuperação (ex.: 8 códigos de 10 caracteres).
   - Backend retorna QR code (otpauth://) para o app e os backup codes para download/mostrar uma vez.
   - Usuário insere um código TOTP do app para confirmar enrolamento.
   - Após verificação bem-sucedida, backend marca `2fa_enabled = true`.

2. Login com 2FA
   - Usuário fornece credenciais (email/senha).
   - Se credenciais válidas e `2fa_enabled = true`, solicitar código 2FA (TOTP/SMS/e-mail).
   - Verificar código; se válido, conceder sessão/ token JWT marcando `2fa_passed=true`.

3. Recuperação / Fallback
   - Usuário pode usar um backup code (consumível) para entrar.
   - Caso SMS/e-mail usado, enviar código temporário com expiração curta (ex.: 5 minutos).

## Requisitos de backend / endpoints sugeridos

- `POST /api/2fa/enroll` -> inicia enrolamento, retorna secret + QR (base64) + backup codes (mostrar só uma vez)
- `POST /api/2fa/confirm` -> verifica código de enrolamento (TOTP) e ativa 2FA
- `POST /api/2fa/verify` -> verifica código no fluxo de login
- `POST /api/2fa/send-fallback` -> envia SMS ou e-mail com código (se habilitado)
- `POST /api/2fa/backup-codes/regenerate` -> gera novos backup codes (revoke anteriores)
- `POST /api/2fa/disable` -> desativa 2FA (exigir re-autenticação)

Observações: todos os endpoints devem validar a sessão do usuário atual e exigir autenticação forte quando apropriado.

## Modelagem de dados (campos recomendados)

- `users` (tabela/coleção) campos adicionais sugeridos:
  - `2fa_enabled` (boolean)
  - `2fa_method` (enum: 'totp'|'sms'|'email'|'push')
  - `2fa_secret` (string cifrada) — para TOTP
  - `phone` (string) — número verificado para SMS
  - `email_verified` (boolean) — para fallback por email
  - `backup_codes` (array de hashes)
  - `2fa_enabled_at` (timestamp)

## Detalhes TOTP técnicos

- Algoritmo: HMAC-SHA1 (compatível) ou SHA256
- Digitos: 6
- Time step: 30s
- Janela de verificação: permitir `-1..+1` steps por conveniência

## Backup codes

- Gerar 8-12 códigos aleatórios, armazenar apenas o hash.
- Cada código é de uso único; após uso, marcar como consumido.
- UI deve instruir usuário a salvar/baixar os códigos no momento da geração.

## Rate limiting e proteção contra abuso

- Limitar tentativas por identificação (IP + user) com políticas de escalonamento.
- Monitorar tentativas falhas e enviar alertas para contas com muitas falhas.

## Logs e auditoria

- Registrar eventos: `2fa_enrollment_requested`, `2fa_enrollment_confirmed`, `2fa_verification_success`, `2fa_verification_failed`, `backup_codes_regenerated`, `2fa_disabled`.

## Testes

- Criar testes unitários para: geração/verificação TOTP, geração/uso de backup codes, endpoints de enrolamento e verificação, rate limiting.

## Integração com provedores (opcional)

- SMS: Twilio, Vonage, MessageBird — avaliar custo e cobertura.
- E-mail: SendGrid, Mailgun ou SMTP direto.
- Push: Firebase Cloud Messaging (FCM) para Android/web; APNs para iOS.

## Considerações de privacidade e conformidade

- Evitar armazenar números de telefone/e-mails em texto claro quando possível; aplicar políticas de retenção.

## Próximos passos recomendados

1. Implementar suporte TOTP básico (biblioteca para gerar/verificar) e endpoints de enrolamento/confirm.
2. Armazenar segredos cifrados e gerar backup codes hashed.
3. Fazer UI minimal para enrolamento e verificação.
4. Opcional: integrar SMS/email como fallback.

---

Autor: Felipe Augusto dos Santos Silva — RA: 25003353
