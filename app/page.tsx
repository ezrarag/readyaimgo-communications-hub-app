/**
 * Root page - API-only backend, minimal UI
 */

export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui' }}>
      <h1>Readyaimgo Communications Hub API</h1>
      <p>WhatsApp webhook handler and communications pipeline</p>
      <p>
        <strong>Webhook endpoint:</strong>{' '}
        <code>/api/webhooks/whatsapp</code>
      </p>
      <p>
        <strong>Admin seed endpoint:</strong>{' '}
        <code>/api/admin/seed/ibms</code>
      </p>
    </main>
  );
}




