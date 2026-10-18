import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { importPKCS8, SignJWT } from 'npm:jose@5';

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
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return jsonResponse({ error: 'Method not allowed.' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const firebaseJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
    const authorization = request.headers.get('Authorization') ?? '';
    const accessToken = authorization.replace(/^Bearer\s+/i, '');
    if (!supabaseUrl || !serviceRoleKey || !firebaseJson || !accessToken) {
      return jsonResponse({ error: 'Function is not configured or caller is not authenticated.' }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !authData.user) return jsonResponse({ error: 'Unauthorized.' }, 401);

    const { messageId } = await request.json();
    if (typeof messageId !== 'string' || !messageId) {
      return jsonResponse({ error: 'messageId is required.' }, 400);
    }

    const { data: message, error: messageError } = await admin
      .from('messages')
      .select('id, chatId, senderId, text, type')
      .eq('id', messageId)
      .maybeSingle();
    if (messageError || !message) return jsonResponse({ error: 'Message not found.' }, 404);
    if (message.senderId !== authData.user.id) return jsonResponse({ error: 'Forbidden.' }, 403);
    if (message.type !== 'text') return jsonResponse({ sent: 0 });

    const { data: chat, error: chatError } = await admin
      .from('chats')
      .select('buyerId, sellerId')
      .eq('id', message.chatId)
      .maybeSingle();
    if (chatError || !chat) return jsonResponse({ error: 'Conversation not found.' }, 404);

    const recipientId = chat.buyerId === authData.user.id
      ? chat.sellerId
      : chat.sellerId === authData.user.id
      ? chat.buyerId
      : null;
    if (!recipientId) return jsonResponse({ error: 'Caller is not a conversation participant.' }, 403);

    const { data: devices, error: deviceError } = await admin
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', recipientId);
    if (deviceError) throw deviceError;
    if (!devices?.length) return jsonResponse({ sent: 0, reason: 'No registered devices.' });

    const [profileResult] = await Promise.all([
      admin.from('profiles').select('displayName').eq('id', authData.user.id).maybeSingle(),
    ]);
    const senderName = profileResult.data?.displayName?.toString().trim() || 'New message';
    const rawText = message.text?.toString() ?? '';
    const body = rawText.length > 140 ? `${rawText.slice(0, 137)}...` : rawText;
    const serviceAccount = JSON.parse(firebaseJson) as Record<string, string>;
    const projectId = serviceAccount.project_id;
    const fcmToken = await firebaseAccessToken(serviceAccount);

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
              notification: { title: senderName, body },
              data: {
                chatId: message.chatId.toString(),
                messageId: message.id.toString(),
              },
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
            .eq('user_id', recipientId)
            .eq('fcm_token', device.fcm_token);
        }
        console.error(`FCM send failed (${response.status}).`);
      }
    }

    return jsonResponse({ sent });
  } catch (error) {
    console.error('send-chat-notification failed:', error);
    return jsonResponse({ error: 'Could not send push notification.' }, 500);
  }
});
