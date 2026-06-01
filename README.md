# SMTP Tester

A small Windows GUI for testing SMTP servers with authentication and TLS/SSL. Built with PowerShell and WinForms—no install required beyond PowerShell.

**License:** [MIT](LICENSE)

## Requirements

- Windows
- Windows PowerShell 5.1 or later (included on Windows)
- Outbound network access to your SMTP host/port

## Quick start

1. Copy `smtptest.config.json.example` to `smtptest.config.json` and edit your settings.
2. Double-click **`smtptest.cmd`**, or run:

   ```powershell
   powershell -STA -ExecutionPolicy Bypass -File .\smtptest.ps1
   ```

   WinForms needs **`-STA`** when launching from a shell.

3. Use **Test TCP Port** to verify connectivity, then **Send Test Email** to test TLS and authentication.

## Configuration

Settings are loaded from `smtptest.config.json` in the same folder as the script (created via **Save Config** or by copying the example file).

| Key | Description |
|-----|-------------|
| `SmtpServer` | SMTP hostname |
| `Port` | Port number (e.g. `587`) |
| `From` | Sender email address |
| `To` | Recipient email address |
| `Username` | Auth username (often same as From) |
| `Password` | Auth password (stored in plain text—keep the file private) |
| `Subject` | Test message subject |
| `Body` | Test message body |
| `UseTls` | `true` / `false` — enable TLS/SSL |
| `UseAuth` | `true` / `false` — enable SMTP authentication |

Custom config path:

```powershell
powershell -STA -File .\smtptest.ps1 -ConfigPath "C:\path\my-smtp.json"
```

**Do not commit** `smtptest.config.json` if it contains real credentials.

## Common ports

| Port | Typical use |
|------|-------------|
| **25** | SMTP (often plain; many ISPs block outbound 25) |
| **587** | Submission with STARTTLS (most hosted mail) |
| **465** | SMTPS (implicit SSL/TLS) |

Click the port links under the Port field to preset port and TLS, or set them in the config file.

## Versioning

This project uses **[Calendar Versioning (CalVer)](https://calver.org/)** in the form **`YYYY.M.D`** (year, month, day of release), for example `2026.6.1`.

The current version is in the [`VERSION`](VERSION) file and shown in the window title and log on startup. Bump `VERSION` when you cut a new release.

## Files

| File | Purpose |
|------|---------|
| `smtptest.ps1` | Main application |
| `smtptest.cmd` | Launcher (sets STA mode) |
| `smtptest.config.json.example` | Config template |
| `VERSION` | Release version (CalVer) |
| `LICENSE` | MIT license |

## Distribution zip

`smtptester.zip` contains the files needed to share the tool (not your personal `smtptest.config.json`).
