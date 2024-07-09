# Testing cross-domain cookies in Safari

This is a local reproduction for how Safari handles third-party cookies when "Cross-Site Tracking Prevention" is 
enabled.

```
Browser:                                                                    Server:
                                                                                                     
┌─ test.parent-app.io ────────────────┐                                     ┌─ api.embedded-app.io ─┐
│                                     │                                     │                       │
│  ┌─ iFrame: app.embedded-app.io ─┐  │                                     │  API service          │
│  │                               │←─│────────────────────────────────────→│                       │   
│  │  ┌ ─ ─ ─ ─ ─ ┐                │  │                                     └───────────────────────┘   
│  │     Sign In                   │  │   ┌─ popup: app.embedded-app.io ─┐              ↑
│  │  └ ─ ─ ─ ─ ─ ┘                │  │   │                              │              │  
│  │                               │←─│──→│  Sign In experience          │←─────────────┘  
│  └───────────────────────────────┘  │   │                              │
└─────────────────────────────────────┘   └──────────────────────────────┘
```

# Prerequisites

1. macOS
2. Docker + Docker Compose
3. Node.js 20+
4. pnpm

# Run

1. Execute `./setup-certs.sh` to generate a local self-signed root certificate and SSL certificates for the
   host names shown in the diagram above. This will remove existing certificates and add the Root CA to the
   System Keychain. It will also add several entries to the `/etc/hosts` file.
2. Build and run a local Nginx docker container: `./start-nginx.sh`. This will remove previous containers.
3. Run `pnpm i` to install dependencies.
4. Run `pnpm start` to start the local server.
5. Open Safari and navigate to `https://test.parent-app.io`.
