/**
 * Root layout for Next.js App Router
 * Minimal layout for API-only backend
 */

export const metadata = {
  title: 'Readyaimgo Communications Hub API',
  description: 'WhatsApp webhook handler and communications pipeline',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}








