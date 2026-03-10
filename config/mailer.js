const nodemailer = require('nodemailer');
const handlebars = require('handlebars');
const fs = require('fs');
const path = require('path');

// Create transporter based on environment
const createTransporter = () => {
  // For development/testing - use ethereal.email (fake SMTP)
  if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
    return nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      auth: {
        user: process.env.ETHEREAL_USER || 'ethereal.user@ethereal.email',
        pass: process.env.ETHEREAL_PASS || 'ethereal_pass'
      }
    });
  }

  // Production SMTP configuration
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT || 587,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD
    },
    tls: {
      rejectUnauthorized: process.env.NODE_ENV === 'production' // Only reject in production
    }
  });
};

// Email templates
const loadTemplate = (templateName, data) => {
  const templatePath = path.join(__dirname, '../templates/emails', `${templateName}.html`);
  
  try {
    const source = fs.readFileSync(templatePath, 'utf8');
    const template = handlebars.compile(source);
    return template(data);
  } catch (err) {
    console.error(`Error loading email template ${templateName}:`, err);
    // Fallback to simple text if template not found
    return `
      <h2>${data.subject}</h2>
      <p>${data.message}</p>
      ${data.link ? `<p><a href="${data.link}">${data.linkText || 'Click here'}</a></p>` : ''}
    `;
  }
};

// Email sender class
class Mailer {
  constructor() {
    this.transporter = null;
    this.initialize();
  }

  initialize() {
    try {
      this.transporter = createTransporter();
      console.log('✅ Mailer initialized successfully');
    } catch (err) {
      console.error('❌ Failed to initialize mailer:', err);
    }
  }

  async sendEmail({ to, subject, html, text = null }) {
    if (!this.transporter) {
      console.error('❌ Mailer not initialized');
      return { success: false, error: 'Mailer not initialized' };
    }

    const mailOptions = {
      from: `"${process.env.MAIL_FROM_NAME || 'Voucher Platform'}" <${process.env.MAIL_FROM_ADDRESS || 'noreply@voucherplatform.com'}>`,
      to,
      subject,
      html,
      text: text || html.replace(/<[^>]*>/g, '') // Strip HTML for plain text
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      
      // For ethereal.email, log the preview URL
      if (process.env.NODE_ENV === 'development' && info.messageId) {
        console.log('📧 Email preview URL:', nodemailer.getTestMessageUrl(info));
      }
      
      console.log(`✅ Email sent to ${to}:`, info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (err) {
      console.error('❌ Failed to send email:', err);
      return { success: false, error: err.message };
    }
  }

  // Password reset email
  async sendPasswordResetEmail(to, resetToken, userName = 'User') {
    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    
    const html = loadTemplate('password-reset', {
      name: userName,
      link: resetLink,
      expiresIn: '1 hour',
      subject: 'Reset Your Password - Voucher Platform'
    });

    return await this.sendEmail({
      to,
      subject: 'Reset Your Password - Voucher Platform',
      html
    });
  }

  // Welcome email for new users
  async sendWelcomeEmail(to, userName) {
    const html = loadTemplate('welcome', {
      name: userName,
      loginLink: `${process.env.FRONTEND_URL}/login`,
      subject: 'Welcome to Voucher Platform'
    });

    return await this.sendEmail({
      to,
      subject: 'Welcome to Voucher Platform',
      html
    });
  }

  // Password changed confirmation
  async sendPasswordChangedEmail(to, userName) {
    const html = loadTemplate('password-changed', {
      name: userName,
      supportLink: `${process.env.FRONTEND_URL}/support`,
      subject: 'Your Password Has Been Changed'
    });

    return await this.sendEmail({
      to,
      subject: 'Your Password Has Been Changed - Voucher Platform',
      html
    });
  }
}

// Create singleton instance
const mailer = new Mailer();

module.exports = mailer;