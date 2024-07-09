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

This project assume you're on a Mac and have Docker installed.

# Run

1. Execute `./setup-certs.sh` to generate a local self-signed root certificate and certificates for the host 
   names shown in the diagram above. This will remove existing certificates and add the Root CA to the
   System Keychain.
2. Build and run a local Nginx docker container: `./start-nginx.sh`. This will remove previous containers.
3. 
