export default function Hero() {
  return (
    <section className="relative flex min-h-[60vh] flex-col items-center justify-center overflow-hidden px-4 pt-24 pb-0 sm:px-6 lg:px-8">
      {/* Background gradient effects */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/2 h-[600px] w-[600px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/5 blur-[120px]" />
        <div className="absolute right-1/4 bottom-1/4 h-[400px] w-[400px] rounded-full bg-accent-cyan/5 blur-[100px]" />
      </div>

      <div className="relative z-10 mx-auto max-w-4xl text-center">
        {/* Headline */}
        <h1 className="font-heading text-4xl font-bold leading-tight tracking-tight text-text-primary sm:text-5xl md:text-6xl lg:text-7xl">
          Your Daily AI News,{" "}
          <span className="bg-gradient-to-r from-primary to-accent-cyan bg-clip-text text-transparent">
            Summarized
          </span>
        </h1>

        {/* Subtitle */}
        <p className="mx-auto mt-6 max-w-2xl font-body text-lg leading-relaxed text-text-secondary sm:text-xl">
          Stay ahead of AI with curated briefings, audio summaries, and category
          deep dives. The most important AI news delivered to you every day.
        </p>

        {/* CTA Buttons */}
        <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <a
            href="https://app.ai-briefing.cc"
            target="_blank"
            rel="noopener noreferrer"
            className="group cursor-pointer inline-flex items-center gap-2 rounded-full bg-primary px-8 py-3.5 text-base font-semibold text-black shadow-[0_0_24px_rgba(30,215,96,0.3)] transition-all duration-200 hover:bg-primary-alt hover:shadow-[0_0_32px_rgba(30,215,96,0.4)]"
          >
            Start Free
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
          <a
            href="#features"
            className="cursor-pointer inline-flex items-center gap-2 rounded-full border border-border-light px-8 py-3.5 text-base font-semibold text-text-primary transition-colors duration-200 hover:border-text-tertiary hover:bg-bg-surface"
          >
            Learn More
          </a>
        </div>
      </div>

    </section>
  );
}
