import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { GoogleAuthService } from './google-auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly googleAuth: GoogleAuthService,
  ) {}

  @Post('signup')
  async signup(
    @Body() body: { email?: string; password?: string; displayName?: string },
  ) {
    if (!body.email || !EMAIL_PATTERN.test(body.email)) {
      return {
        statusCode: 400,
        message: 'A valid email is required',
        path: '/auth/signup',
      };
    }
    if (!body.password || body.password.length < 8) {
      return {
        statusCode: 400,
        message: 'Password must be at least 8 characters',
        path: '/auth/signup',
      };
    }
    return this.auth.signup({
      email: body.email,
      password: body.password,
      displayName: body.displayName,
    });
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() body: { email?: string; password?: string }) {
    return this.auth.login({
      email: body.email ?? '',
      password: body.password ?? '',
    });
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  async google(@Body() body: { idToken?: string }) {
    return this.googleAuth.authenticate(body.idToken ?? '');
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() body: { refreshToken?: string }) {
    return this.auth.refresh(body.refreshToken ?? '');
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.ACCEPTED)
  async forgotPassword(@Body() body: { email?: string }) {
    if (body.email) {
      await this.auth.forgotPassword(body.email);
    }
    return { message: 'Check your email' };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() body: { token?: string; newPassword?: string }) {
    if (!body.token || !body.newPassword || body.newPassword.length < 8) {
      return {
        statusCode: 400,
        message: 'A valid token and password (≥ 8 chars) are required',
        path: '/auth/reset-password',
      };
    }
    await this.auth.resetPassword(body.token, body.newPassword);
    return { message: 'Password reset successfully' };
  }

  @Get('reset')
  resetLanding(@Req() req: { query: { token?: string } }) {
    const token = req.query.token ?? '';
    const deepLink = `spotifyclone://auth/reset?token=${encodeURIComponent(token)}`;

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Password - Spotify</title>
  <style>
    body {
      background-color: #121212;
      color: #FFFFFF;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      box-sizing: border-box;
    }
    .card {
      background-color: #181818;
      border-radius: 12px;
      padding: 32px 24px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
      text-align: center;
    }
    .logo {
      font-size: 32px;
      margin-bottom: 8px;
    }
    h1 {
      font-size: 24px;
      margin: 0 0 8px 0;
      color: #1DB954;
    }
    p {
      color: #B3B3B3;
      font-size: 14px;
      line-height: 1.5;
      margin: 0 0 24px 0;
    }
    .btn {
      display: block;
      background-color: #1DB954;
      color: #000000;
      font-weight: 700;
      font-size: 15px;
      padding: 14px 20px;
      border-radius: 500px;
      text-decoration: none;
      border: none;
      cursor: pointer;
      width: 100%;
      box-sizing: border-box;
      transition: transform 0.1s, background-color 0.2s;
    }
    .btn:hover {
      background-color: #1ed760;
      transform: scale(1.02);
    }
    .divider {
      display: flex;
      align-items: center;
      text-align: center;
      margin: 24px 0;
      color: #727272;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .divider::before, .divider::after {
      content: '';
      flex: 1;
      border-bottom: 1px solid #282828;
    }
    .divider::before { margin-right: 12px; }
    .divider::after { margin-left: 12px; }
    .form-group {
      text-align: left;
      margin-bottom: 16px;
    }
    label {
      display: block;
      font-size: 13px;
      margin-bottom: 6px;
      color: #FFFFFF;
      font-weight: 600;
    }
    input {
      width: 100%;
      padding: 12px;
      background-color: #282828;
      border: 1px solid #3E3E3E;
      border-radius: 4px;
      color: #FFFFFF;
      font-size: 14px;
      box-sizing: border-box;
    }
    input:focus {
      outline: none;
      border-color: #1DB954;
    }
    #status-msg {
      margin-top: 16px;
      font-size: 14px;
      font-weight: 500;
    }
    .success { color: #1DB954; }
    .error { color: #E91429; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🎵</div>
    <h1>Reset Password</h1>
    <p>Open the app directly or set a new password below.</p>
    
    <a id="app-btn" class="btn" href="${deepLink}">Open in Spotify App</a>

    <div class="divider">OR RESET HERE</div>

    <form id="reset-form">
      <div class="form-group">
        <label for="newPassword">New Password</label>
        <input type="password" id="newPassword" name="newPassword" placeholder="Min. 8 characters" required minlength="8">
      </div>
      <div class="form-group">
        <label for="confirmPassword">Confirm New Password</label>
        <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Re-enter password" required minlength="8">
      </div>
      <button type="submit" class="btn" style="background-color: #FFFFFF; color: #000000;">Save New Password</button>
    </form>
    <div id="status-msg"></div>
  </div>

  <script>
    // Automatically attempt to trigger deep link on mobile browsers
    window.addEventListener('DOMContentLoaded', () => {
      if (${JSON.stringify(Boolean(token))}) {
        setTimeout(() => {
          window.location.href = "${deepLink}";
        }, 300);
      }
    });

    document.getElementById('reset-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const p1 = document.getElementById('newPassword').value;
      const p2 = document.getElementById('confirmPassword').value;
      const msg = document.getElementById('status-msg');
      msg.textContent = '';
      msg.className = '';

      if (p1 !== p2) {
        msg.textContent = 'Passwords do not match';
        msg.className = 'error';
        return;
      }

      try {
        const res = await fetch('/auth/reset-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token: ${JSON.stringify(token)}, newPassword: p1 })
        });
        const data = await res.json();
        if (res.ok) {
          msg.textContent = 'Password reset successfully! You can now log into the app.';
          msg.className = 'success';
          document.getElementById('reset-form').reset();
        } else {
          msg.textContent = data.message || 'Failed to reset password';
          msg.className = 'error';
        }
      } catch (err) {
        msg.textContent = 'Network error. Please try again.';
        msg.className = 'error';
      }
    });
  </script>
</body>
</html>`;
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: { user: { userId: string; email: string } }) {
    return { id: req.user.userId, email: req.user.email };
  }
}
