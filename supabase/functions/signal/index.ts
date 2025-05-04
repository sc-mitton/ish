import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import * as apple_notification_jwt from '@narumincho/apple-notification-jwt';

const apnSecret = Deno.env.get('APN_SECRET');
const teamId = Deno.env.get('APPLE_TEAM_ID');
const keyId = Deno.env.get('APPLE_KEY_ID');

if (!apnSecret || !teamId || !keyId) {
  throw new Error('APN_SECRET, APPLE_TEAM_ID, and APPLE_KEY_ID must be set');
}

// Store active WebSocket connections
const connections = new Set<WebSocket>();

interface Fight {
  from: string;
  to: string;
  id: string;
}

const isFight = (data: unknown): data is Fight => {
  return (
    typeof data === 'object' &&
    data !== null &&
    'from' in data &&
    'to' in data &&
    'id' in data
  );
};

const alertUserOfFight = async (fight: Fight) => {
  const jwt = await apple_notification_jwt.createAppleNotificationJwt({
    secret: apnSecret,
    iat: new Date(),
    iss: teamId,
    kid: keyId,
  });

  const response = await fetch(Deno.env.get('APN_SERVER')!, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({}),
  });
};

Deno.serve(async (req) => {
  // Check if the request is a WebSocket upgrade request
  if (req.headers.get('upgrade') === 'websocket') {
    const { socket, response } = Deno.upgradeWebSocket(req);

    socket.onopen = () => connections.add(socket);
    socket.onmessage = (e) => {
      const data = JSON.parse(e.data);
      isFight(data) && alertUserOfFight(data);
    };
    socket.onclose = () => connections.delete(socket);
    socket.onerror = () => connections.delete(socket);

    return response;
  }

  return new Response(null, {
    headers: { 'Content-Type': 'application/json' },
  });
});
