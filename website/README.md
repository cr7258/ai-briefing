# AI Briefing - Website

Marketing landing page for [AI Briefing](https://app.ai-briefing.cc), built with Next.js 16 + Tailwind CSS v4.

## Getting Started

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Build for Production

```bash
npm run build
```

The output is a fully static site (SSG) that can be deployed anywhere.

## Tech Stack

- **Next.js 16** (App Router, Static Site Generation)
- **Tailwind CSS v4** (CSS-based theme configuration)
- **TypeScript**
- **Fonts**: Space Grotesk (headings) + DM Sans (body) via `next/font/google`

## Project Structure

```
website/
  src/
    app/
      layout.tsx        # Root layout: fonts, metadata
      page.tsx           # Home page: assembles all sections
      globals.css        # Tailwind theme + custom styles
    components/
      Navbar.tsx         # Floating sticky navbar
      Hero.tsx           # Hero section
      Features.tsx       # 3 feature cards
      Pricing.tsx        # Pricing card ($3/month)
      CallToAction.tsx   # Final CTA section
      Footer.tsx         # Footer with links
```
