# AI Briefing - Website

Marketing landing page for [AI Briefing](https://ai-briefing.vercel.app), built with Next.js 16 + Tailwind CSS v4.

## Getting Started

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Adding Product Screenshots

Screenshot placeholders are located throughout the page. To replace them:

1. Add your screenshots to `public/screenshots/`
2. Edit the corresponding component in `src/components/`:
   - **Hero screenshot**: `Hero.tsx` — replace the placeholder `<div>` with:
     ```tsx
     <Image src="/screenshots/hero.png" alt="AI Briefing App" fill className="object-cover rounded-xl" />
     ```
   - **Showcase screenshots**: `Showcase.tsx` — replace each placeholder `<div>` with an `<Image>` component
3. Import `Image` from `next/image` at the top of the file

Recommended image sizes:
- Hero: **1920 x 1080px**
- Showcase items: **1280 x 800px**

## Build for Production

```bash
npm run build
```

The output is a fully static site (SSG) that can be deployed anywhere.

## Deploy to Vercel

The easiest way to deploy:

```bash
npx vercel
```

Or connect the repository to [Vercel](https://vercel.com) and set the **Root Directory** to `website`.

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
      Hero.tsx           # Hero section with screenshot placeholder
      Features.tsx       # 3 feature cards
      Showcase.tsx       # Product showcase with screenshot placeholders
      Pricing.tsx        # Pricing card ($3/month)
      CallToAction.tsx   # Final CTA section
      Footer.tsx         # Footer with links
  public/
    screenshots/         # Add your product screenshots here
```
