import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service - AI Briefing",
  description: "Terms of Service for AI Briefing — the rules and guidelines for using our service.",
};

export default function TermsOfService() {
  return (
    <>
      <Navbar />
      <main className="mx-auto max-w-3xl px-4 pt-32 pb-24 sm:px-6 lg:px-8">
        <h1 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
          Terms of Service
        </h1>
        <p className="mt-2 font-body text-sm text-text-tertiary">
          Last updated: February 15, 2026
        </p>

        <div className="mt-10 space-y-10 font-body text-base leading-relaxed text-text-secondary">
          {/* Intro */}
          <section>
            <p>
              These Terms of Service govern your access to and use of{" "}
              <a href="https://app.ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                app.ai-briefing.cc
              </a>{" "}
              and the AI Briefing mobile app, operated by AI Briefing (&quot;we&quot;, &quot;us&quot;, or &quot;our&quot;).
            </p>
            <p className="mt-4">
              By using the Service, you confirm that you have read, understood and agree to be bound by these Terms of Service, as amended from time to time.
            </p>
            <p className="mt-4">
              Should you have any questions or comments, please contact us at:{" "}
              <a href="mailto:support@ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                support@ai-briefing.cc
              </a>
            </p>
          </section>

          {/* 1. Service Description */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              1. Service Description
            </h2>
            <p className="mt-4">
              AI Briefing is a daily AI news aggregation and summarization service. We crawl publicly available RSS feeds, use artificial intelligence to classify and summarize articles, and deliver daily briefings, category deep dives, and audio summaries to our users.
            </p>
          </section>

          {/* 2. Accounts */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              2. Accounts
            </h2>
            <p className="mt-4">
              To access certain features of the Service, you must sign in using a supported third-party account (Google, GitHub, or Apple) via OAuth. You are responsible for maintaining the security of your account and for all activities that occur under it. We may add or remove supported sign-in providers at any time.
            </p>
          </section>

          {/* 3. Free Trial */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              3. Free Trial
            </h2>
            <p className="mt-4">
              Non-subscribed logged-in users may access up to 3 pieces of content for free (the &quot;Free Trial&quot;). This quota is shared across daily briefings and category briefings. Revisiting content you have already accessed does not consume additional quota. No credit card is required for the Free Trial.            </p>
          </section>

          {/* 4. Paid Subscriptions */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              4. Paid Subscriptions
            </h2>
            <div className="mt-4 space-y-4">
              <p>
                AI Briefing offers a paid subscription plan (&quot;Pro Plan&quot;) at $3 USD per month that grants unlimited access to all briefings, category deep dives, and audio summaries.
              </p>
              <p>
                On the web, payments are processed by Creem, our Merchant of Record. On iOS, payments are processed through Apple&apos;s App Store via In-App Purchase. By subscribing, you agree to the applicable payment provider&apos;s terms of service in addition to these Terms.
              </p>
              <p>
                <strong className="text-text-primary">Auto-Renewal:</strong> Your subscription will automatically renew each month at the then-current rate. You will be charged at the start of each renewal period.
              </p>
              <p>
                <strong className="text-text-primary">Cancellation:</strong> You may cancel your subscription at any time. On the web, cancel via your account settings or the Creem customer portal. On iOS, cancel via your Apple ID subscription settings. Upon cancellation, you will retain access until the end of the current billing period.
              </p>
              <p>
                <strong className="text-text-primary">Refunds:</strong> Subscription fees are generally non-refundable. If you believe you are entitled to a refund, please contact us at{" "}
                <a href="mailto:support@ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                  support@ai-briefing.cc
                </a>{" "}
                and we will review your request on a case-by-case basis. We will respond to all refund requests within 3 business days.
              </p>
              <p>
                <strong className="text-text-primary">Price Changes:</strong> We reserve the right to change subscription pricing. Any price changes will take effect at the start of your next billing cycle following reasonable notice.
              </p>
            </div>
          </section>

          {/* 5. Content and Intellectual Property */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              5. Content and Intellectual Property
            </h2>
            <div className="mt-4 space-y-4">
              <p>
                The AI-generated summaries, briefings, audio content, and all other materials available through the Service (&quot;Content&quot;) are owned by AI Briefing or its licensors.
              </p>
              <p>
                The original news articles summarized by our Service remain the property of their respective authors and publishers. We link back to original sources and do not claim ownership over third-party content.
              </p>
              <p>
                You may not reproduce, distribute, modify, or create derivative works from our Content without prior written permission.
              </p>
            </div>
          </section>

          {/* 6. AI-Generated Content Disclaimer */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              6. AI-Generated Content Disclaimer
            </h2>
            <p className="mt-4">
              Our briefings and summaries are generated using artificial intelligence. While we strive for accuracy, AI-generated content may contain errors, omissions, or inaccuracies. The Content is provided for informational purposes only and does not constitute professional advice. You should verify important information from original sources before relying on it.
            </p>
          </section>

          {/* 7. Acceptable Use */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              7. Acceptable Use
            </h2>
            <p className="mt-4">You agree not to:</p>
            <ul className="mt-4 list-disc space-y-2 pl-5">
              <li>Use the Service for any unlawful purpose</li>
              <li>Scrape, crawl, or use automated tools to access the Service</li>
              <li>Redistribute, republish, or resell our Content</li>
              <li>Attempt to gain unauthorized access to the Service or its related systems</li>
              <li>Interfere with the operation or security of the Service</li>
              <li>Share your account credentials with others or create multiple accounts to circumvent limits</li>
            </ul>
          </section>

          {/* 8. Contact Us */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              8. Contact Us
            </h2>
            <p className="mt-4">
              If you have any questions about these Terms, please contact us at:{" "}
              <a href="mailto:support@ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                support@ai-briefing.cc
              </a>
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
