const showcaseItems = [
  {
    title: "Daily Briefing Overview",
    description:
      "Get a comprehensive summary of the day's most important AI news. Our AI reads and analyzes dozens of sources so you don't have to.",
    badge: "Daily Updates",
    placeholder: "Insert daily briefing screenshot",
    recommended: "1280 x 800px",
  },
  {
    title: "Category Deep Dives",
    description:
      "Dive deeper into specific topics like LLMs, AI Agents, Coding Tools, Infrastructure, Research, and more. Each category gets its own focused summary.",
    badge: "9 Categories",
    placeholder: "Insert category view screenshot",
    recommended: "1280 x 800px",
    reversed: true,
  },
  {
    title: "Audio Summaries",
    description:
      "Listen to your daily AI briefing with high-quality synthesized audio. Perfect for staying informed during commutes, workouts, or any time you prefer listening.",
    badge: "Listen Anywhere",
    placeholder: "Insert audio player screenshot",
    recommended: "1280 x 800px",
  },
];

export default function Showcase() {
  return (
    <section id="showcase" className="relative px-4 py-24 sm:px-6 lg:px-8">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border to-transparent" />
      </div>

      <div className="relative mx-auto max-w-6xl">
        {/* Section header */}
        <div className="mx-auto max-w-2xl text-center">
          <p className="mb-3 font-body text-sm font-semibold uppercase tracking-wider text-primary">
            Product
          </p>
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            See it in action
          </h2>
          <p className="mt-4 font-body text-lg text-text-secondary">
            A beautiful, dark-mode interface designed for focused reading and
            listening.
          </p>
        </div>

        {/* Showcase items */}
        <div className="mt-20 flex flex-col gap-24">
          {showcaseItems.map((item, index) => (
            <div
              key={index}
              className={`flex flex-col items-center gap-10 lg:flex-row lg:gap-16 ${
                item.reversed ? "lg:flex-row-reverse" : ""
              }`}
            >
              {/* Screenshot placeholder */}
              <div className="w-full flex-shrink-0 lg:w-[55%]">
                <div className="overflow-hidden rounded-2xl border border-border bg-bg-surface p-1 shadow-xl">
                  <div className="relative aspect-[16/10] w-full overflow-hidden rounded-xl border-2 border-dashed border-border-light bg-bg-surface-variant">
                    {/* Replace this div with: <Image src="/screenshots/feature-N.png" alt={item.title} fill className="object-cover" /> */}
                    <div className="flex h-full w-full flex-col items-center justify-center gap-3">
                      <svg
                        className="h-10 w-10 text-text-muted"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        strokeWidth={1.5}
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z"
                        />
                      </svg>
                      <p className="font-body text-sm text-text-muted">
                        {item.placeholder}
                      </p>
                      <p className="font-body text-xs text-text-muted">
                        Recommended: {item.recommended}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Text content */}
              <div className="w-full lg:w-[45%]">
                <span className="inline-flex items-center rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                  {item.badge}
                </span>
                <h3 className="mt-4 font-heading text-2xl font-bold text-text-primary sm:text-3xl">
                  {item.title}
                </h3>
                <p className="mt-4 font-body text-base leading-relaxed text-text-secondary">
                  {item.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
