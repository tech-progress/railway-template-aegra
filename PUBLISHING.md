# Publishing Aegra agent backend

The current template release is `v1.0.0`. The private authoring source is `aegra-agent-backend` in this repository; Railway builds the public `tech-progress/railway-template-aegra` mirror at `release-v1`. Run `scripts/check-aegra-standalone.sh` before each release.

Run `bun install --frozen-lockfile`, `./scripts/verify.sh`, clean-volume Compose startup, the authenticated smoke, initialized restart, and the forced mid-run restart workflow. Then deploy `.railway/railway.ts` to a disposable source project with fixed temporary secrets, create the Aegra public domain, and confirm one running and zero crashed replicas per service.

Generate and restore the stored draft so it has generated secrets, exact descriptions, source branch, build path, volumes, and port. Deploy that draft into a fresh project and repeat the smoke and restart checks before publishing:

```bash
railway templates publish TEMPLATE_ID \
  --category AI/ML \
  --description "Authenticated Aegra Agent Protocol backend with durable PostgreSQL and Redis." \
  --readme-file MARKETPLACE.md \
  --json
```

Run `./scripts/audit-template.sh TEMPLATE_ID PUBLISHED`, delete all disposable Railway projects and local Compose volumes, update findings and progress, tag this repository as `aegra-agent-backend-v1.0.0`, and tag the public mirror as `v1.0.0` with `release-v1` at the same commit.
