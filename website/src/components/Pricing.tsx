const includedFeatures = [
  "Daily AI news briefings",
  "Audio summaries",
  "Category deep dives (LLM, Agent, Coding, Infra...)",
  "Full archive access",
  "New features as they launch",
];

export default function Pricing() {
  return (
    <section id="pricing" className="relative px-4 py-24 sm:px-6 lg:px-8">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border to-transparent" />
      </div>

      <div className="relative mx-auto max-w-4xl">
        {/* Section header */}
        <div className="mx-auto max-w-2xl text-center">
          <p className="mb-3 font-body text-sm font-semibold uppercase tracking-wider text-primary">
            Pricing
          </p>
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Simple, affordable pricing
          </h2>
          <p className="mt-4 font-body text-lg text-text-secondary">
            Start with 3 free previews. Then unlock unlimited access for less
            than the price of a coffee.
          </p>
        </div>

        {/* Pricing card */}
        <div className="mx-auto mt-12 max-w-md">
          <div className="overflow-hidden rounded-2xl border border-primary/30 bg-bg-surface shadow-xl shadow-primary/5">
            {/* Card header */}
            <div className="bg-gradient-to-b from-bg-elevated to-bg-surface px-8 pt-8 pb-6 text-center">
              <p className="font-body text-sm font-medium text-text-secondary">
                Pro Plan
              </p>
              <div className="mt-4 flex items-baseline justify-center gap-1">
                <span className="font-heading text-lg text-text-secondary">
                  $
                </span>
                <span className="font-heading text-6xl font-bold tracking-tight text-text-primary">
                  3
                </span>
                <span className="ml-2 font-body text-base text-text-tertiary">
                  / month
                </span>
              </div>
              <p className="mt-2 font-body text-sm text-text-tertiary">
                Cancel anytime
              </p>
            </div>

            {/* Divider */}
            <div className="h-px bg-gradient-to-r from-transparent via-border to-transparent" />

            {/* Features list */}
            <div className="px-8 py-6">
              <ul className="flex flex-col gap-4">
                {includedFeatures.map((feature, index) => (
                  <li key={index} className="flex items-start gap-3">
                    <svg
                      className="mt-0.5 h-5 w-5 flex-shrink-0 text-primary"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={2}
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                      />
                    </svg>
                    <span className="font-body text-sm text-text-secondary">
                      {feature}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            {/* CTA */}
            <div className="px-8 pb-8">
              <a
                href="https://app.ai-briefing.cc"
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full cursor-pointer rounded-xl bg-primary py-3.5 text-center font-body text-base font-semibold text-black transition-colors duration-200 hover:bg-primary-alt"
              >
                Subscribe Now
              </a>
              <p className="mt-4 text-center font-body text-xs text-text-muted">
                Secure payment powered by Creem. Cancel anytime from your
                account settings.
              </p>
            </div>
          </div>
        </div>

        {/* Free tier note */}
        <div className="mx-auto mt-8 max-w-md text-center">
          <p className="font-body text-sm text-text-tertiary">
            Not ready to subscribe?{" "}
            <a
              href="https://app.ai-briefing.cc"
              target="_blank"
              rel="noopener noreferrer"
              className="cursor-pointer text-primary transition-colors duration-200 hover:text-primary-alt"
            >
              Try 3 briefings free
            </a>{" "}
            — no credit card required.
          </p>
        </div>
      </div>
    </section>
  );
}
