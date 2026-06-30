// =====================================================================
// Jaune — Edge Function `notify-apero`
// Diffuse une notif push aux AMIS de l'appelant quand il « attaque l'apéro »
// (1er verre du soir). Appelée par l'app via `supabase.functions.invoke`.
//
// Flux :
//   1. Authentifie l'appelant (JWT) → uid + vérifie l'opt-in apero_broadcast.
//   2. Récupère ses amis acceptés (friendships).
//   3. Récupère leurs device_tokens.
//   4. Envoie un push FCM HTTP v1 à chaque token.
//
// Secrets à configurer (Dashboard → Edge Functions → Secrets) :
//   FCM_SERVICE_ACCOUNT  = le JSON complet du compte de service Firebase
//                          (Firebase Console → Paramètres → Comptes de service
//                          → Générer une nouvelle clé privée).
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont injectés automatiquement.
//
// Déploiement : `supabase functions deploy notify-apero`
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

// --- OAuth : token d'accès Google à partir du compte de service ---------
// FCM HTTP v1 exige un Bearer OAuth2 (scope firebase.messaging). On signe
// un JWT RS256 avec la clé privée du compte de service, puis on l'échange.
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const unsigned = `${enc(header)}.${enc(claims)}`;

  // Import de la clé privée PEM (PKCS#8) pour RS256.
  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const jwt = `${unsigned}.${sigB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`OAuth token failed: ${JSON.stringify(json)}`);
  }
  return json.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");
    if (!jwt) return new Response("Unauthorized", { status: 401 });

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 1. Authentifier l'appelant.
    const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
    if (userErr || !userData.user) {
      return new Response("Unauthorized", { status: 401 });
    }
    const senderId = userData.user.id;

    // Profil émetteur : pseudo + opt-in.
    const { data: profile } = await supabase
      .from("profiles")
      .select("username, apero_broadcast")
      .eq("id", senderId)
      .single();

    if (!profile?.apero_broadcast) {
      return new Response(JSON.stringify({ sent: 0, reason: "opt_out" }), {
        headers: { "Content-Type": "application/json" },
      });
    }
    const senderName = (profile.username as string)?.trim() || "Un ami";

    // 2. Amis acceptés (lien dans un sens ou l'autre).
    const { data: links } = await supabase
      .from("friendships")
      .select("requester, addressee")
      .eq("status", "accepted")
      .or(`requester.eq.${senderId},addressee.eq.${senderId}`);

    const friendIds = (links ?? [])
      .map((l) => (l.requester === senderId ? l.addressee : l.requester))
      .filter((id) => id && id !== senderId);

    if (friendIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "no_friends" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Tokens des amis.
    const { data: tokenRows } = await supabase
      .from("device_tokens")
      .select("token")
      .in("user_id", friendIds);

    const tokens = (tokenRows ?? []).map((r) => r.token as string);
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Push FCM v1.
    const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!) as ServiceAccount;
    const accessToken = await getAccessToken(sa);
    const endpoint =
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let sent = 0;
    await Promise.all(
      tokens.map(async (token) => {
        const message = {
          message: {
            token,
            notification: {
              title: `🍋 ${senderName} attaque l'apéro`,
              body: "Son citron compte sur toi ce soir 👀",
            },
            // Données pour un éventuel formatage/localisation côté client.
            data: { type: "apero", sender: senderName },
            apns: { payload: { aps: { sound: "default" } } },
            android: { notification: { sound: "default" } },
          },
        };
        const r = await fetch(endpoint, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(message),
        });
        if (r.ok) sent++;
        else console.error("FCM error", await r.text());
      }),
    );

    return new Response(JSON.stringify({ sent }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-apero error", e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
