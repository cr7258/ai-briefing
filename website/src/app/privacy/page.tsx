import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy - AI Briefing",
  description: "Privacy Policy for AI Briefing — how we collect, use, and protect your information.",
};

export default function PrivacyPolicy() {
  return (
    <>
      <Navbar />
      <main className="mx-auto max-w-3xl px-4 pt-32 pb-24 sm:px-6 lg:px-8">
        <h1 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
          Privacy Policy
        </h1>
        <p className="mt-2 font-body text-sm text-text-tertiary">
          Last updated: February 11, 2026
        </p>

        <div className="mt-10 space-y-10 font-body text-base leading-relaxed text-text-secondary">
          {/* Intro */}
          <section>
            <p>
              AI Briefing (&quot;we&quot;, &quot;us&quot;, or &quot;our&quot;) operates the web application at{" "}
              <a href="https://app.ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                app.ai-briefing.cc
              </a>{" "}
              . This Privacy Policy explains how we collect, use, disclose, and protect your information when you use our service.
            </p>
          </section>

          {/* 1. Information We Collect */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              1. Information We Collect
            </h2>
            <div className="mt-4 space-y-4">
              <div>
                <h3 className="font-heading text-base font-semibold text-text-primary">
                  Account Information
                </h3>
                <p className="mt-1">
                  When you sign in via a third-party OAuth provider (Google or GitHub), we receive your name, email address, and profile avatar from that provider. We do not receive or store your passwords. The specific information we receive depends on the provider you use and your account settings with that provider.
                </p>
              </div>
              <div>
                <h3 className="font-heading text-base font-semibold text-text-primary">
                  Payment Information
                </h3>
                <p className="mt-1">
                  Payments are processed by our payment partner, Creem. We do not directly collect or store your credit card numbers or banking details. Creem may collect payment information in accordance with their own privacy policy.
                </p>
              </div>
              <div>
                <h3 className="font-heading text-base font-semibold text-text-primary">
                  Usage Data
                </h3>
                <p className="mt-1">
                  We collect information about how you interact with the Service, including which briefings you view and your free trial usage (to track your 3 free content accesses).
                </p>
              </div>
              <div>
                <h3 className="font-heading text-base font-semibold text-text-primary">
                  Cookies
                </h3>
                <p className="mt-1">
                  We do not use cookies. Authentication session data is stored locally in your browser.
                </p>
              </div>
            </div>
          </section>

          {/* 2. Recipients of Data and Data Transfers */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              2. Recipients of Data and Data Transfers
            </h2>
            <p className="mt-4">
              We do not sell your personal information. We only share your data with trusted service providers as necessary to operate the Service, or when required by law.
            </p>
            <p className="mt-4">
              Your data may be stored and processed in countries where our service providers operate. By using the service, you consent to the storage of your information in these locations.
            </p>
          </section>

          {/* 3. Data Retention */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              3. Data Retention
            </h2>
            <p className="mt-4">
              We retain your account information for as long as your account is active. If you wish to delete your account and associated data, please contact us at the email below.
            </p>
          </section>

          {/* 4. Your Rights */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              4. Your Rights
            </h2>
            <p className="mt-4">
              Depending on your jurisdiction, you may have the right to:
            </p>
            <ul className="mt-4 list-disc space-y-2 pl-5">
              <li>Access the personal information we hold about you</li>
              <li>Request correction of inaccurate information</li>
              <li>Request deletion of your personal information (&quot;right to be forgotten&quot;)</li>
              <li>Request restriction of processing</li>
              <li>Data portability — receive your data in a structured, machine-readable format</li>
              <li>Object to processing of your personal data</li>
              <li>Withdraw consent at any time</li>
            </ul>
            <p className="mt-4">
              To exercise any of these rights, please contact us at{" "}
              <a href="mailto:support@ai-briefing.cc" className="text-primary hover:text-primary-alt transition-colors">
                support@ai-briefing.cc
              </a>.
            </p>
          </section>

          {/* 5. Contact Us */}
          <section>
            <h2 className="font-heading text-xl font-semibold text-text-primary">
              5. Contact Us
            </h2>
            <p className="mt-4">
              If you have any questions about this Privacy Policy, please contact us at:{" "}
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
