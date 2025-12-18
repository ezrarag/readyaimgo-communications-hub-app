/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Allow raw body for webhook signature verification
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
}

module.exports = nextConfig




