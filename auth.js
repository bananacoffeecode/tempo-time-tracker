const { google } = require('googleapis');
const http = require('http');
const url = require('url');
const path = require('path');
const fs = require('fs');
const { app, shell } = require('electron');

const SCOPES = ['https://www.googleapis.com/auth/calendar.events'];

function getCredentialsPath() {
  if (app.isPackaged) {
    // Bundled via extraResources — sits alongside the asar
    return path.join(process.resourcesPath, 'credentials.json');
  }
  // Development: credentials.json next to main.js
  return path.join(__dirname, 'credentials.json');
}

let store;

function getStore() {
  if (!store) {
    const Store = require('electron-store');
    store = new Store({ name: 'auth-tokens' });
  }
  return store;
}

function loadCredentials() {
  const credPath = getCredentialsPath();
  if (!fs.existsSync(credPath)) {
    return null;
  }
  try {
    const raw = fs.readFileSync(credPath, 'utf8');
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
}

function getOAuth2Client() {
  const creds = loadCredentials();
  if (!creds) return null;
  return new google.auth.OAuth2(
    creds.client_id,
    creds.client_secret,
    null // redirect_uri set dynamically per-flow
  );
}

function hasValidToken() {
  const s = getStore();
  const tokens = s.get('tokens');
  if (!tokens) return false;
  // Check if refresh_token exists (can always get new access token)
  return !!tokens.refresh_token;
}

function getAuthenticatedClient() {
  const creds = loadCredentials();
  if (!creds) throw new Error('NO_CREDENTIALS');

  const oauth2Client = new google.auth.OAuth2(
    creds.client_id,
    creds.client_secret,
    'urn:ietf:wg:oauth:2.0:oob' // fallback, overridden below
  );

  const tokens = getStore().get('tokens');
  if (!tokens) throw new Error('NO_TOKEN');

  oauth2Client.setCredentials(tokens);

  // Auto-save refreshed tokens
  oauth2Client.on('tokens', (newTokens) => {
    const existing = getStore().get('tokens') || {};
    getStore().set('tokens', { ...existing, ...newTokens });
  });

  return oauth2Client;
}

function startOAuthFlow() {
  return new Promise((resolve, reject) => {
    const creds = loadCredentials();
    if (!creds) {
      reject(new Error('NO_CREDENTIALS'));
      return;
    }

    // Find a free port
    const server = http.createServer();
    server.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      const redirectUri = `http://127.0.0.1:${port}`;

      const oauth2Client = new google.auth.OAuth2(
        creds.client_id,
        creds.client_secret,
        redirectUri
      );

      const authUrl = oauth2Client.generateAuthUrl({
        access_type: 'offline',
        scope: SCOPES,
        prompt: 'consent',
      });

      // Open browser
      shell.openExternal(authUrl);

      server.on('request', async (req, res) => {
        const parsed = url.parse(req.url, true);
        if (parsed.pathname !== '/') {
          res.end();
          return;
        }

        const code = parsed.query.code;
        if (!code) {
          res.writeHead(400);
          res.end('Missing authorization code.');
          reject(new Error('Missing code'));
          server.close();
          return;
        }

        // Success page
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Connected — Tempo</title>
            <link href="https://fonts.googleapis.com/css2?family=Crimson+Text:ital,wght@0,600;1,400&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
            <style>
              *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
              body {
                font-family: 'DM Sans', system-ui, sans-serif;
                background: #FFFFFF;
                color: #1A1A1A;
                -webkit-font-smoothing: antialiased;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
                padding: 24px;
              }
              .card {
                text-align: center;
                max-width: 420px;
                width: 100%;
              }
              .icon {
                width: 56px;
                height: 56px;
                background: rgba(124, 169, 3, 0.12);
                border-radius: 16px;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 24px;
              }
              .checkmark {
                width: 28px;
                height: 28px;
                stroke: #7CA903;
                fill: none;
                stroke-width: 2.5;
                stroke-linecap: round;
                stroke-linejoin: round;
              }
              h1 {
                font-family: 'Crimson Text', Georgia, serif;
                font-size: 2rem;
                font-weight: 600;
                color: #1A1A1A;
                margin-bottom: 10px;
              }
              p {
                font-size: 1rem;
                line-height: 1.6;
                color: #6B6B6B;
              }
              .logo {
                position: fixed;
                top: 24px;
                left: 50%;
                transform: translateX(-50%);
                font-family: 'Crimson Text', Georgia, serif;
                font-weight: 600;
                font-size: 1.1rem;
                letter-spacing: 0.08em;
                color: #1A1A1A;
              }
            </style>
          </head>
          <body>
            <span class="logo">TEMPO</span>
            <div class="card">
              <div class="icon">
                <svg class="checkmark" viewBox="0 0 24 24">
                  <polyline points="20 6 9 17 4 12"/>
                </svg>
              </div>
              <h1>Google Calendar connected.</h1>
              <p>You can close this window and return to the app.</p>
            </div>
          </body>
          </html>
        `);

        try {
          const { tokens } = await oauth2Client.getToken(code);
          getStore().set('tokens', tokens);
          resolve(tokens);
        } catch (err) {
          reject(err);
        } finally {
          server.close();
        }
      });
    });

    server.on('error', reject);
  });
}

function getUserEmail() {
  return getStore().get('userEmail', null);
}
function setUserEmail(email) {
  getStore().set('userEmail', email.trim());
}
async function revokeToken() {
  getStore().delete('tokens');
  getStore().delete('userEmail');
}

module.exports = { hasValidToken, getAuthenticatedClient, startOAuthFlow, loadCredentials,
                   getUserEmail, setUserEmail, revokeToken };
