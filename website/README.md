Marketing site for the Windows 11 Gaming Toolkit.

This site intentionally reflects the product's aggressive posture:
- `APPLY-EVERYTHING.ps1` is the main CTA
- security/functionality trade-offs are explicit
- rollback is described as manifest-backed where available, not universally perfect

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

Main source lives under `src/`.

Before publishing, set real values for the release/source URLs in `src/lib/constants.ts` or wire them through your build pipeline.

## Publish Checklist

- Set the repository URL and releases URL.
- Confirm the site copy still matches the current script behavior.
- Run `npm run lint`.
- Run `npm run build`.
