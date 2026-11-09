import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const PUBLIC_BUCKETS = new Set(['listing-images', 'profile-images', 'service-images']);
const MAX_BYTES = 10 * 1024 * 1024;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function detectImage(bytes: Uint8Array): { ext: string; type: string } | null {
  if (bytes.length > 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return { ext: 'jpg', type: 'image/jpeg' };
  }
  if (
    bytes.length > 8 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e &&
    bytes[3] === 0x47
  ) {
    return { ext: 'png', type: 'image/png' };
  }
  if (
    bytes.length > 12 &&
    String.fromCharCode(...bytes.slice(0, 4)) === 'RIFF' &&
    String.fromCharCode(...bytes.slice(8, 12)) === 'WEBP'
  ) {
    return { ext: 'webp', type: 'image/webp' };
  }
  return null;
}

function isUnsafe(result: Record<string, unknown>): boolean {
  const nudity = (result.nudity ?? {}) as Record<string, number>;
  const explicit = Math.max(
    nudity.sexual_activity ?? 0,
    nudity.sexual_display ?? 0,
    nudity.erotica ?? 0,
  );
  return explicit >= 0.5 || (nudity.very_suggestive ?? 0) >= 0.8;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return jsonResponse({ error: 'Method not allowed.' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const apiUser = Deno.env.get('SIGHTENGINE_API_USER');
    const apiSecret = Deno.env.get('SIGHTENGINE_API_SECRET');
    const accessToken = (request.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    if (!supabaseUrl || !serviceRoleKey || !accessToken) {
      return jsonResponse({ error: 'Function is not configured or caller is not authenticated.' }, 401);
    }
    if (!apiUser || !apiSecret) {
      console.error('moderate-upload: Sightengine credentials are missing.');
      return jsonResponse({ error: 'moderation_unavailable' }, 503);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !authData.user) return jsonResponse({ error: 'Unauthorized.' }, 401);

    const bucket = new URL(request.url).searchParams.get('bucket') ?? '';
    if (!PUBLIC_BUCKETS.has(bucket)) return jsonResponse({ error: 'Unknown bucket.' }, 400);

    const form = await request.formData();
    const file = form.get('file');
    if (!(file instanceof File)) return jsonResponse({ error: 'file is required.' }, 400);
    if (file.size > MAX_BYTES) return jsonResponse({ error: 'Image is larger than 10 MB.' }, 413);

    const bytes = new Uint8Array(await file.arrayBuffer());
    const kind = detectImage(bytes);
    if (!kind) return jsonResponse({ error: 'Only JPEG, PNG or WebP images are allowed.' }, 415);

    const check = new FormData();
    check.append('media', new Blob([bytes], { type: kind.type }), `upload.${kind.ext}`);
    check.append('models', 'nudity-2.1');
    check.append('api_user', apiUser);
    check.append('api_secret', apiSecret);
    const moderation = await fetch('https://api.sightengine.com/1.0/check.json', {
      method: 'POST',
      body: check,
    });
    const result = await moderation.json().catch(() => ({}));
    if (!moderation.ok || result.status !== 'success') {
      console.error(`moderate-upload: Sightengine check failed (${moderation.status}).`, result?.error);
      return jsonResponse({ error: 'moderation_unavailable' }, 503);
    }
    if (isUnsafe(result)) return jsonResponse({ error: 'inappropriate_image' }, 422);

    const path = `${authData.user.id}/${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${kind.ext}`;
    const { error: uploadError } = await admin.storage
      .from(bucket)
      .upload(path, bytes, { contentType: kind.type, upsert: false });
    if (uploadError) throw uploadError;

    const { data } = admin.storage.from(bucket).getPublicUrl(path);
    return jsonResponse({ url: data.publicUrl, path });
  } catch (error) {
    console.error('moderate-upload failed:', error);
    return jsonResponse({ error: 'upload_failed' }, 500);
  }
});
