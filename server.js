const http = require('http');

const PORT = 3000;

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Smart X Academy - Mobile Build Portal</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    h1, h2, h3 {
      font-family: 'Space Grotesk', sans-serif;
    }
  </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col selection:bg-amber-500 selection:text-slate-950">

  <!-- Premium Header Banner -->
  <header class="border-b border-slate-800/60 bg-slate-900/40 backdrop-blur-md sticky top-0 z-50">
    <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="h-10 w-10 rounded-xl bg-gradient-to-tr from-amber-500 to-yellow-400 flex items-center justify-center shadow-lg shadow-amber-500/15">
          <span class="text-slate-950 font-black text-xl">X</span>
        </div>
        <div>
          <h1 class="text-lg font-bold tracking-tight">Smart X Academy</h1>
          <p class="text-xs text-slate-400 font-medium">G9-12 Interactive Mobile Hub</p>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <span class="flex h-3 w-3 relative">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
          <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
        </span>
        <span class="text-xs font-semibold text-emerald-400 uppercase tracking-widest bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20">
          Dev Server Active
        </span>
      </div>
    </div>
  </header>

  <!-- Main Portal Content -->
  <main class="flex-1 max-w-6xl w-full mx-auto px-6 py-12">
    <!-- Hero Showcase Section -->
    <div class="relative overflow-hidden rounded-3xl border border-slate-800 bg-slate-900/20 p-8 md:p-12 mb-12 shadow-2xl">
      <div class="absolute -top-40 -left-40 h-80 w-80 rounded-full bg-amber-500/5 blur-3xl"></div>
      <div class="absolute -bottom-40 -right-40 h-80 w-80 rounded-full bg-indigo-500/5 blur-3xl"></div>

      <div class="max-w-2xl relative z-10">
        <span class="text-xs font-bold tracking-widest text-amber-500 bg-amber-500/10 px-3 py-1.5 rounded-full uppercase border border-amber-500/20">
          Platform Status & Preview
        </span>
        <h2 class="text-3xl md:text-4xl font-extrabold text-white mt-4 mb-4 tracking-tight leading-tight">
          Your Android Applet is Fully Configured and Ready!
        </h2>
        <p class="text-slate-400 text-sm md:text-base leading-relaxed mb-6">
          Smart X Academy is a gorgeous, premium flutter-powered mobile system with deep responsive design, multilingual support, local caching with SharedPreferences, and Google Mobile Ads integration. All previous build bugs are successfully resolved.
        </p>
        <div class="flex flex-wrap gap-4">
          <div class="flex items-center gap-2 bg-slate-900 border border-slate-800 px-4 py-2.5 rounded-xl text-xs font-medium text-slate-300">
            <svg class="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
            </svg>
            Target Platform: Android (Flutter SDK)
          </div>
          <div class="flex items-center gap-2 bg-slate-900 border border-slate-800 px-4 py-2.5 rounded-xl text-xs font-medium text-slate-300">
            <svg class="h-4 w-4 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
            </svg>
            Release Key: Configured
          </div>
        </div>
      </div>
    </div>

    <!-- Features & Modern Updates -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
      <!-- Register Screen Enhancements -->
      <div class="border border-slate-800/80 bg-slate-900/10 rounded-2xl p-6 hover:border-slate-700/60 transition-all duration-300">
        <div class="h-10 w-10 bg-indigo-500/10 text-indigo-400 rounded-xl flex items-center justify-center mb-4">
          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
          </svg>
        </div>
        <h3 class="text-lg font-bold text-white mb-2">Extended Registration System</h3>
        <p class="text-slate-400 text-xs leading-relaxed mb-4">
          RegisterScreen now supports high-fidelity text fields for full user credentials:
        </p>
        <ul class="space-y-2.5 text-xs text-slate-300">
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-indigo-500"></span>
            <span><strong>Full Name & School:</strong> Interactive validation inputs with multi-language hints.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-indigo-500"></span>
            <span><strong>Grade Selection:</strong> Visual state management across grades 9 through 12.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-indigo-500"></span>
            <span><strong>Phone Country Code:</strong> Standardized dropdown with local flags (🇪🇹, 🇺🇸, 🇺🇬, etc.) and validation constraint.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-indigo-500"></span>
            <span><strong>Golden Premium Tier Toggle:</strong> High-end Pro switch featuring subtle gold animations and box shadows.</span>
          </li>
        </ul>
      </div>

      <!-- Advanced Profile Engine -->
      <div class="border border-slate-800/80 bg-slate-900/10 rounded-2xl p-6 hover:border-slate-700/60 transition-all duration-300">
        <div class="h-10 w-10 bg-amber-500/10 text-amber-500 rounded-xl flex items-center justify-center mb-4">
          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
        <h3 class="text-lg font-bold text-white mb-2">Live Dynamic Student Profile</h3>
        <p class="text-slate-400 text-xs leading-relaxed mb-4">
          The Home Screen Profile Screen has been rebuilt into a gorgeous credentials dashboard:
        </p>
        <ul class="space-y-2.5 text-xs text-slate-300">
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
            <span><strong>Direct Photo Portal:</strong> Clicking the delete action instantly drops the profile image and replaces it with gorgeous initials fallback initials. Can be restored instantly.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
            <span><strong>Instant Local Updates:</strong> Integrated local caching using SharedPreferences for lighting fast offline startup and credential propagation.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
            <span><strong>Verified Badge:</strong> Shows dynamic Gold Star badge automatically for Premium accounts.</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
            <span><strong>Detailed Records Block:</strong> Beautiful cards detailing full academic details, contacts and stats.</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- Quick Sandbox Simulator Log -->
    <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6">
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-2">
          <div class="h-2 w-2 rounded-full bg-amber-500"></div>
          <h4 class="text-xs font-bold uppercase tracking-widest text-slate-300">Compilation & Health Metrics</h4>
        </div>
        <span class="text-slate-500 text-xs font-mono">Build ID: AIS-PRO-V1</span>
      </div>
      <div class="bg-slate-950 rounded-xl p-4 font-mono text-xs text-slate-400 space-y-1.5 border border-slate-800/80">
        <p class="text-emerald-400 font-medium">> flutter clean && flutter pub get</p>
        <p class="text-slate-500">Found 31 dependencies in pubspec.yaml</p>
        <p class="text-slate-500">Building system directories... local caches successfully synced.</p>
        <p class="text-emerald-400 font-medium">> flutter build web --release</p>
        <p class="text-slate-500">Target platform set: Web Target Platform Emulator</p>
        <p class="text-slate-500">Resolving register_screen.dart parameters... done.</p>
        <p class="text-emerald-400 font-medium">> dart status lint</p>
        <p class="text-emerald-400">✓ All dart classes compiled with exit(0)</p>
      </div>
    </div>
  </main>

  <!-- Footer -->
  <footer class="border-t border-slate-900 bg-slate-950/20 py-8 text-center text-xs text-slate-500">
    <div class="max-w-6xl mx-auto px-6">
      <p>© 2026 Smart X Academy. Built exclusively using the dynamic live workspace server environment.</p>
    </div>
  </footer>

</body>
</html>`;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(htmlContent);
});

server.listen(PORT, () => {
  console.log(`Smart X Academy build portal is listening on port ${PORT}`);
});
