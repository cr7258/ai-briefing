export default function CallToAction() {
  return (
    <section className="relative px-4 py-24 sm:px-6 lg:px-8">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border to-transparent" />
      </div>

      <div className="relative mx-auto max-w-4xl">
        <div className="overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-bg-elevated via-bg-surface to-bg-surface-variant p-12 text-center sm:p-16">
          {/* Decorative glow */}
          <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-3xl">
            <div className="absolute top-0 left-1/2 h-[300px] w-[400px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/10 blur-[80px]" />
          </div>

          <div className="relative z-10">
            <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
              Ready to stay ahead of AI?
            </h2>
            <p className="mx-auto mt-4 max-w-xl font-body text-lg text-text-secondary">
              Join readers who start their day with AI Briefing. No noise, just
              the news that matters.
            </p>
            <div className="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <a
                href="https://app.ai-briefing.cc"
                target="_blank"
                rel="noopener noreferrer"
                className="group cursor-pointer inline-flex items-center gap-2 rounded-full bg-primary px-8 py-3.5 text-base font-semibold text-black shadow-[0_0_24px_rgba(30,215,96,0.3)] transition-all duration-200 hover:bg-primary-alt hover:shadow-[0_0_32px_rgba(30,215,96,0.4)]"
              >
                Get Started for Free
                <svg
                  className="h-4 w-4 transition-transform duration-200 group-hover:translate-x-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
                  />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
