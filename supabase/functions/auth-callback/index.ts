import "@supabase/functions-js/edge-runtime.d.ts"

Deno.serve((req: Request) => {
  const url = new URL(req.url);
  const params = url.search;
  const appUrl = `io.supabase.instainsight://login-callback${params}`;
  const escaped = appUrl
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");

  // We return HTML (not a 302) because Instagram's `l.instagram.com`
  // interstitial swallows 302s to custom schemes — the page goes blank and
  // the user has to manually close it. HTML with multiple redirect
  // mechanisms (JS replace + meta-refresh + visible tap target) is the most
  // compatible way to bounce Chrome Custom Tabs / in-app WebViews back to
  // the app, including on Huawei browsers where JS sometimes fails.
  const html = `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0;url=${escaped}">
<title>جارٍ العودة…</title>
<style>
  html,body{margin:0;padding:0;background:#0e0a18;color:#f5f5f5;
    font-family:-apple-system,Segoe UI,Roboto,sans-serif;
    display:flex;align-items:center;justify-content:center;
    min-height:100vh;text-align:center}
  .card{padding:24px;max-width:320px}
  .spin{width:28px;height:28px;border:3px solid rgba(255,255,255,.15);
    border-top-color:#E0C06B;border-radius:50%;margin:0 auto 14px;
    animation:s .8s linear infinite}
  @keyframes s{to{transform:rotate(360deg)}}
  a.btn{display:inline-block;margin-top:18px;padding:12px 20px;
    background:linear-gradient(135deg,#E0C06B,#B9894A);color:#000;
    font-weight:700;border-radius:12px;text-decoration:none}
  p.hint{opacity:.6;font-size:13px;margin-top:16px}
</style>
</head>
<body>
<div class="card">
  <div class="spin"></div>
  <div>جارٍ إكمال تسجيل الدخول…</div>
  <a class="btn" id="go" href="${escaped}">افتح التطبيق</a>
  <p class="hint">لم يفتح تلقائياً؟ اضغط الزر أعلاه.</p>
</div>
<script>
(function(){
  var u=${JSON.stringify(appUrl)};
  // Try immediate navigation — most reliable in Custom Tabs.
  try{ window.location.replace(u); }catch(e){}
  // Backup: simulate a click on the visible link.
  setTimeout(function(){
    try{ document.getElementById('go').click(); }catch(e){}
  },250);
  // Last resort: meta-refresh (declared in <head>) fires at t=0.
})();
</script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: new Headers({
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-cache, no-store",
    }),
  });
});
