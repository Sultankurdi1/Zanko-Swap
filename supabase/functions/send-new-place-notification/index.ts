import { createClient } from '@supabase/supabase-js';
import { importPKCS8, SignJWT } from 'jose';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function firebaseAccessToken(serviceAccount: Record<string, string>) {
  const privateKey = serviceAccount.private_key?.replace(/\\n/g, '\n');
  if (!privateKey || !serviceAccount.client_email || !serviceAccount.project_id) {
    throw new Error('Firebase service account JSON is incomplete.');
  }
  const key = await importPKCS8(privateKey, 'RS256');
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(key);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const result = await response.json();
  if (!response.ok || typeof result.access_token !== 'string') {
    throw new Error(`Firebase OAuth failed (${response.status}).`);
  }
  return result.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return jsonResponse({ error: 'Method not allowed.' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const firebaseJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
    const accessToken = (request.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    if (!supabaseUrl || !serviceRoleKey || !firebaseJson || !accessToken) {
      return jsonResponse({ error: 'Function is not configured or caller is not authenticated.' }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !authData.user) return jsonResponse({ error: 'Unauthorized.' }, 401);

    const { serviceId } = await request.json();
    if (typeof serviceId !== 'string' || !/^\d+$/.test(serviceId)) {
      return jsonResponse({ error: 'serviceId must be a numeric id.' }, 400);
    }
    const { data: place, error: placeError } = await admin
      .from('services')
      .select('id, ownerId, name, type, address, active')
      .eq('id', serviceId)
      .maybeSingle();
    if (placeError || !place) return jsonResponse({ error: 'Place not found.' }, 404);
    if (place.ownerId !== authData.user.id) return jsonResponse({ error: 'Forbidden.' }, 403);
    if (place.active !== true) return jsonResponse({ sent: 0, reason: 'Place is inactive.' });

    const { data: devices, error: deviceError } = await admin
      .from('user_devices')
      .select('user_id, fcm_token');
    if (deviceError) throw deviceError;
    if (!devices?.length) return jsonResponse({ sent: 0, reason: 'No registered devices.' });

    const serviceAccount = JSON.parse(firebaseJson) as Record<string, string>;
    const projectId = serviceAccount.project_id;
    const fcmToken = await firebaseAccessToken(serviceAccount);
    const description = [place.name, place.type, place.address]
      .map((value) => value?.toString().trim())
      .filter((value) => value)
      .join(' · ')
      .slice(0, 180);

    let sent = 0;
    for (const device of devices) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${fcmToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: device.fcm_token,
              notification: {
                title: 'شوێنی نوێ زیادکرا · New place added',
                body: description,
              },
              data: { serviceId: String(place.id), route: '/services' },
              android: { priority: 'high' },
            },
          }),
        },
      );
      if (response.ok) {
        sent += 1;
      } else {
        const errorText = await response.text();
        if (errorText.includes('UNREGISTERED') || errorText.includes('NOT_FOUND')) {
          await admin
            .from('user_devices')
            .delete()
            .eq('user_id', device.user_id)
            .eq('fcm_token', device.fcm_token);
        }
        console.error(`FCM send failed (${response.status}).`);
      }
    }
    return jsonResponse({ sent });
  } catch (error) {
    console.error('send-new-place-notification failed:', error);
    return jsonResponse({ error: 'Could not send new-place notification.' }, 500);
  }
});
