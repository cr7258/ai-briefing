import Image from "next/image";

export default function Footer() {
  return (
    <footer className="border-t border-border px-4 py-12 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          {/* Logo & description */}
          <div className="flex flex-col items-center md:items-start">
            <div className="flex items-center gap-2">
              <Image
                src="/logo.jpeg"
                alt="AI Briefing"
                width={38}
                height={28}
                className="h-7 w-9.5 rounded-lg object-cover"
              />
              <span className="font-heading text-lg font-bold text-text-primary">
                AI Briefing
              </span>
            </div>
            <p className="mt-2 max-w-xs text-center font-body text-sm text-text-tertiary md:text-left">
              Your daily AI news, summarized. Stay ahead without the noise.
            </p>
          </div>

          {/* Links */}
          <div className="flex gap-8">
            <div className="flex flex-col gap-3">
              <p className="font-body text-xs font-semibold uppercase tracking-wider text-text-muted">
                Product
              </p>
              <a
                href="#features"
                className="cursor-pointer font-body text-sm text-text-tertiary transition-colors duration-200 hover:text-text-primary"
              >
                Features
              </a>
              <a
                href="#pricing"
                className="cursor-pointer font-body text-sm text-text-tertiary transition-colors duration-200 hover:text-text-primary"
              >
                Pricing
              </a>
            </div>
            <div className="flex flex-col gap-3">
              <p className="font-body text-xs font-semibold uppercase tracking-wider text-text-muted">
                Legal
              </p>
              <a
                href="/privacy"
                className="cursor-pointer font-body text-sm text-text-tertiary transition-colors duration-200 hover:text-text-primary"
              >
                Privacy
              </a>
              <a
                href="/terms"
                className="cursor-pointer font-body text-sm text-text-tertiary transition-colors duration-200 hover:text-text-primary"
              >
                Terms
              </a>
            </div>
            <div className="flex flex-col gap-3">
              <p className="font-body text-xs font-semibold uppercase tracking-wider text-text-muted">
                Support
              </p>
              <a
                href="mailto:support@ai-briefing.cc"
                className="cursor-pointer font-body text-sm text-text-tertiary transition-colors duration-200 hover:text-text-primary"
              >
                support@ai-briefing.cc
              </a>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-10 border-t border-border pt-6 text-center">
          <p className="font-body text-xs text-text-muted">
            &copy; {new Date().getFullYear()} AI Briefing. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
