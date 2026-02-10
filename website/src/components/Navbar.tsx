"use client";

import { useState } from "react";
import Image from "next/image";

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <nav className="fixed top-4 left-4 right-4 z-50 mx-auto max-w-7xl rounded-2xl border border-border bg-bg-primary/80 backdrop-blur-xl">
      <div className="flex items-center justify-between px-6 py-4">
        {/* Logo */}
        <a href="#" className="flex items-center gap-2 cursor-pointer">
          <Image
            src="/logo.jpeg"
            alt="AI Briefing"
            width={44}
            height={32}
            className="h-8 w-11 rounded-lg object-cover"
          />
          <span className="font-heading text-xl font-bold text-text-primary">
            AI Briefing
          </span>
        </a>

        {/* Desktop Nav Links */}
        <div className="hidden items-center gap-8 md:flex">
          <a
            href="#features"
            className="cursor-pointer text-sm font-medium text-text-secondary transition-colors duration-200 hover:text-text-primary"
          >
            Features
          </a>
          <a
            href="#pricing"
            className="cursor-pointer text-sm font-medium text-text-secondary transition-colors duration-200 hover:text-text-primary"
          >
            Pricing
          </a>
        </div>

        {/* CTA Button */}
        <div className="hidden md:block">
          <a
            href="https://app.ai-briefing.cc"
            target="_blank"
            rel="noopener noreferrer"
            className="cursor-pointer rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-black transition-colors duration-200 hover:bg-primary-alt"
          >
            Get Started
          </a>
        </div>

        {/* Mobile Menu Button */}
        <button
          className="cursor-pointer md:hidden"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          aria-label="Toggle menu"
        >
          <svg
            className="h-6 w-6 text-text-primary"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            {mobileMenuOpen ? (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M6 18L18 6M6 6l12 12"
              />
            ) : (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M4 6h16M4 12h16M4 18h16"
              />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="border-t border-border px-6 pb-4 pt-2 md:hidden">
          <div className="flex flex-col gap-3">
            <a
              href="#features"
              className="cursor-pointer py-2 text-sm font-medium text-text-secondary transition-colors duration-200 hover:text-text-primary"
              onClick={() => setMobileMenuOpen(false)}
            >
              Features
            </a>
            <a
              href="#pricing"
              className="cursor-pointer py-2 text-sm font-medium text-text-secondary transition-colors duration-200 hover:text-text-primary"
              onClick={() => setMobileMenuOpen(false)}
            >
              Pricing
            </a>
            <a
              href="https://app.ai-briefing.cc"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-2 cursor-pointer rounded-full bg-primary px-5 py-2.5 text-center text-sm font-semibold text-black transition-colors duration-200 hover:bg-primary-alt"
              onClick={() => setMobileMenuOpen(false)}
            >
              Get Started
            </a>
          </div>
        </div>
      )}
    </nav>
  );
}
