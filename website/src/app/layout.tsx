import type { Metadata } from "next";
import { Space_Grotesk, DM_Sans } from "next/font/google";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "AI Briefing - Your Daily AI News, Summarized",
  description:
    "Stay ahead of AI with daily curated briefings, audio summaries, and category deep dives. Get the most important AI news delivered every day.",
  keywords: ["AI", "news", "briefing", "summary", "daily", "artificial intelligence", "audio"],
  icons: {
    icon: "/logo.jpeg",
    apple: "/logo.jpeg",
  },
  openGraph: {
    title: "AI Briefing - Your Daily AI News, Summarized",
    description:
      "Stay ahead of AI with daily curated briefings, audio summaries, and category deep dives.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${spaceGrotesk.variable} ${dmSans.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
