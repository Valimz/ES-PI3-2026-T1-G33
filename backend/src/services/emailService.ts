import nodemailer from 'nodemailer';

let transporter: nodemailer.Transporter;

// Configuração do Nodemailer
export const initializeEmailService = async () => {
  const user = process.env.SMTP_EMAIL;
  const pass = process.env.SMTP_PASSWORD;

  if (user && pass) {
    // Usar provedor real configurado no .env
    transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false, // usa STARTTLS na porta 587
      auth: {
        user,
        pass,
      },
    });
    console.log(`📧 Nodemailer configurado com o e-mail: ${user}`);
  } else {
    // Criar conta de testes no Ethereal
    console.log('⚠️ Credenciais SMTP não encontradas no .env. Gerando conta de teste Ethereal...');
    const testAccount = await nodemailer.createTestAccount();
    transporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: testAccount.user, // generated ethereal user
        pass: testAccount.pass, // generated ethereal password
      },
    });
    console.log(`📧 Nodemailer configurado com Ethereal Email (Teste): ${testAccount.user}`);
  }
};

export const sendMfaEmail = async (toEmail: string, code: string) => {
  if (!transporter) {
    await initializeEmailService();
  }

  const mailOptions = {
    from: '"Segurança MesclaInvest" <no-reply@mesclainvest.com.br>',
    to: toEmail,
    subject: 'Seu Código de Verificação (MFA) - MesclaInvest',
    text: `Olá!\n\nSeu código de segurança para ativar o MFA é: ${code}\n\nEste código expira em 5 minutos.\n\nAtenciosamente,\nEquipe MesclaInvest`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2 style="color: #0056b3;">Verificação de Dois Fatores (MFA)</h2>
        <p>Olá!</p>
        <p>Você solicitou a ativação da verificação em duas etapas no MesclaInvest. Seu código de segurança é:</p>
        <div style="margin: 20px 0; padding: 15px; background: #f4f4f4; border-radius: 8px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px;">
          ${code}
        </div>
        <p>Este código expira em <strong>5 minutos</strong>.</p>
        <p>Se você não solicitou este código, por favor ignore este e-mail.</p>
        <hr style="border: 1px solid #eee; margin-top: 30px;" />
        <p style="font-size: 12px; color: #999;">Atenciosamente,<br>Equipe MesclaInvest</p>
      </div>
    `,
  };

  const info = await transporter.sendMail(mailOptions);
  
  console.log(`✉️ E-mail de MFA enviado para: ${toEmail}`);
  
  // Se for ethereal, o nodemailer fornece um link para visualizar o email!
  if (info.messageId && nodemailer.getTestMessageUrl(info)) {
    console.log(`\n======================================================`);
    console.log(`🟢 [ETHEREAL] VISUALIZE O E-MAIL AQUI: ${nodemailer.getTestMessageUrl(info)}`);
    console.log(`======================================================\n`);
  }
};
