# Testing cross-domain cookies in Safari

This is a local reproduction for how Safari handles third-party cookies when "Cross-Site Tracking Prevention" is 
enabled.

```
┌─ test.pear.com ───────────────────────────────────┐
│                                                   │
│   ┌─ iFrame: embedded.peach.com ───────┐          │
│   │                                    │          │   
│   │   ┌ ─ ─ ─ ─ ─ ┐                    │          │   
│   │       LOGIN                        │          │   
│   │   └ ─ ─ ─ ─ ─ ┘                    │          │   
│   │                                    │          │   
│   └────────────────────────────────────┘          │
│                                                   │
└───────────────────────────────────────────────────┘
```

This project assume you're on a Mac and have Docker installed.

# Run

1. Execute `./setup-certs.sh` to generate a local self-signed root certificate and certificates for the domains 
   `test.pear.com` and `embedded.peach.com`. This will remove existing certificates and add the Root CA to the
   System Keychain.
2. Build and run a local Nginx docker container: `./start-nginx.sh`. This will remove previous containers.
3. 
