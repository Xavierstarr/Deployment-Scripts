## Intune Deployment Script

This script is intended to be used either as a Platform or Remediation script in Intune.
For enviroments that may already have some hardening policies in place CMD Restrictions will cause installation issues with deployment.
This script will check those restrictions via registry, store to a variable if set, revert continue with install then revert back.

Have not yet got a functioning Mac OS Deployment script in Intune just yet.

# To use the script
- Just update the variables to match your CyberCNS Environment and install type (Scan, Probe or Lightweight)
- Upload to Intune, Target your desired devices via groups or filters
