// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import * as apple_notification_jwt from '@narumincho/apple-notification-jwt';

const apnSecret = Deno.env.get('APN_SECRET');
const teamId = Deno.env.get('APPLE_TEAM_ID');
const keyId = Deno.env.get('APPLE_KEY_ID');

if (!apnSecret || !teamId || !keyId) {
  throw new Error('APN_SECRET, APPLE_TEAM_ID, and APPLE_KEY_ID must be set');
}

Deno.serve(async (req) => {
  const jwt = await apple_notification_jwt.createAppleNotificationJwt({
    secret: apnSecret,
    iat: new Date(),
    iss: teamId,
    kid: keyId,
  });

  return new Response(null, {
    headers: { 'Content-Type': 'application/json' },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/signal' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
