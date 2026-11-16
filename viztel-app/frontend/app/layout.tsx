import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Viztel Fiber',
  description: 'High-speed broadband internet and smart home connectivity',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
