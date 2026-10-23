# R3S packages and Apple-style interfaces

Goal: distribute r3s-monitor and usb-fan-control as standard IPK and signed APK packages, with Apple-inspired visual styling and unchanged device behavior.

1. Freeze SHA-256 of all runtime shell/CGI/config files and normalized browser scripts. Permit only a documented equivalent palette replacement in the browser scripts. Preserve all control IDs, endpoint paths, intervals, thresholds, ports and input constraints.
2. Replace the Monet backgrounds and glass decoration with system typography, neutral grouped surfaces, accessible blue/green/orange/red accents, light mode only and responsive layouts. Check the rendered pages on desktop and mobile with fixture data; exercise all existing actions against a local mock API.
3. Add OpenWrt Makefiles for both packages. Preserve the existing installer hardware/self-check behavior; package setup skips copying already-managed files. Run read-only model/GPIO/interface validation before a live installation, preserve fan config on upgrades and restore kernel USB ownership on removal. Offline image builds skip hardware operations.
4. Add a repository-specific persistent ECDSA key in Actions Secrets and commit its public key. Sign each APK and test the trust failures. Add an installer that verifies the pinned key before first-use import, then calls normal apk/opkg commands.
5. Build both package formats with official SDKs exclusively in GitHub Actions, inspect package payloads and hooks, test package installation in isolated official roots with real dependencies, and document the hardware validation boundary. Push and deliver releases as in the preceding packaging task. Local work is limited to source checks and visual previews.
