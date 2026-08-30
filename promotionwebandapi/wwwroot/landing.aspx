<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Amar Thikanaa - Smart Marketplace ও Local Service Platform</title>
  <meta name="description" content="আমার ঠিকানা দিয়ে ফ্ল্যাট ভাড়া বা বিক্রি, বাসা খোঁজা, শিক্ষক, পিকআপ, জরুরি সহায়তা ও নিরাপদ লেনদেনের সেবা এক জায়গায় পান।">
  <meta property="og:title" content="Amar Thikanaa - Smart Marketplace ও Local Service Platform">
  <meta property="og:description" content="আমার ঠিকানা দিয়ে ফ্ল্যাট ভাড়া বা বিক্রি, বাসা খোঁজা, শিক্ষক, পিকআপ, জরুরি সহায়তা ও নিরাপদ লেনদেনের সেবা এক জায়গায় পান।">
  <meta property="og:image" content="amar_thikanaa_icon.png">
  <meta property="og:type" content="website">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Anek+Bangla:wght@400;500;600;700;800&family=Inter:wght@500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="icon" type="image/png" href="amar_thikanaa_icon.png">
  <style>
    :root {
      --bg: #f6f8ff;
      --dark: #071629;
      --text: #31415a;
      --muted: #6d7b91;
      --primary: #2563eb;
      --primary-dark: #1747b9;
      --secondary: #10b981;
      --accent: #f97316;
      --danger: #ef4444;
      --violet: #7c3aed;
      --teal: #0f766e;
      --card: #ffffff;
      --border: rgba(23, 39, 64, 0.1);
      --shadow: 0 24px 70px rgba(15, 23, 42, 0.13);
      --soft-shadow: 0 16px 40px rgba(15, 23, 42, 0.08);
      --radius-lg: 30px;
      --radius-md: 22px;
      --radius-sm: 14px;
      --max: 100%;
    }

    * { box-sizing: border-box; }
    html { scroll-behavior: smooth; }
    body {
      margin: 0;
      font-family: "Anek Bangla", "Inter", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(37, 99, 235, 0.15), transparent 32%),
        radial-gradient(circle at 88% 8%, rgba(16, 185, 129, 0.15), transparent 30%),
        linear-gradient(180deg, #f7faff 0%, #eef4ff 48%, #ffffff 100%);
      overflow-x: hidden;
    }

    a { color: inherit; text-decoration: none; }
    img { max-width: 100%; display: block; }
    button, input, select, textarea { font: inherit; }
    .svg-sprite { position: absolute; width: 0; height: 0; overflow: hidden; }
    .container { width: 100%; padding: 0 16px; margin: 0 auto; }
    /* .live-chat { display: none !important; } */

    .landing-bulletin {
      display: none;
      position: relative;
      z-index: 60;
      min-height: 38px;
      overflow: hidden;
      color: #ffffff;
      background: linear-gradient(90deg, #0f766e, #2563eb);
      box-shadow: 0 8px 24px rgba(15, 23, 42, 0.14);
    }
    .landing-bulletin.is-visible { display: flex; align-items: center; }
    .landing-bulletin-label {
      position: relative;
      z-index: 2;
      align-self: stretch;
      display: flex;
      align-items: center;
      padding: 0 18px;
      background: #071629;
      font-size: 12px;
      font-weight: 900;
      letter-spacing: .08em;
      text-transform: uppercase;
      white-space: nowrap;
    }
    .landing-bulletin-window { flex: 1; min-width: 0; overflow: hidden; }
    .landing-bulletin-track {
      width: max-content;
      padding: 8px 0;
      font-weight: 700;
      white-space: nowrap;
      animation: bulletin-left-to-right var(--bulletin-duration, 24s) linear infinite;
    }
    .landing-bulletin-track a { color: #ffffff; text-decoration: underline; text-underline-offset: 3px; }
    .landing-bulletin-separator { padding: 0 24px; color: #bfdbfe; }
    .landing-bulletin:hover .landing-bulletin-track { animation-play-state: paused; }
    @keyframes bulletin-left-to-right {
      from { transform: translateX(100vw); }
      to { transform: translateX(-100%); }
    }

    .site-header {
      position: sticky;
      top: 0;
      z-index: 50;
      background: rgba(255, 255, 255, 0.84);
      backdrop-filter: blur(18px);
      border-bottom: 1px solid rgba(15, 23, 42, 0.08);
    }

    .navbar {
      width: 100%;
      padding: 0 16px;
      min-height: 78px;
      margin: 0 auto;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
    }

    .brand { display: flex; align-items: center; min-width: 230px; }
    .brand-text { display: grid; gap: 3px; }
    .brand-text img { width: 180px; max-height: 42px; object-fit: contain; object-position: left center; }
    .brand-text small { color: var(--muted); font-size: 13px; line-height: 1.15; }

    .nav-links { display: flex; align-items: center; justify-content: center; gap: 8px; }
    .nav-links a {
      padding: 10px 13px;
      border-radius: 999px;
      font-size: 15px;
      font-weight: 700;
      color: #43536b;
      transition: 0.25s ease;
    }
    .nav-links a:hover,
    .nav-links a.active { background: #eff6ff; color: var(--primary); }

    .top-actions { display: flex; align-items: center; gap: 10px; }
    .top-login-btn,
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      border: 0;
      border-radius: 999px;
      font-weight: 800;
      cursor: pointer;
      transition: transform .22s ease, box-shadow .22s ease, background .22s ease;
      white-space: nowrap;
    }
    .top-login-btn { padding: 11px 18px; color: #fff; background: var(--dark); }
    .top-login-btn:hover, .btn:hover { transform: translateY(-2px); }
    .btn { padding: 13px 20px; font-size: 16px; }
    .btn-primary { color: #fff; background: linear-gradient(135deg, var(--primary), #1d4ed8); box-shadow: 0 15px 30px rgba(37, 99, 235, 0.25); }
    .btn-primary:hover { box-shadow: 0 18px 38px rgba(37, 99, 235, 0.34); }
    .btn-light { color: var(--dark); background: rgba(255, 255, 255, 0.9); border: 1px solid var(--border); }
    .btn-green { color: #fff; background: linear-gradient(135deg, #10b981, #059669); box-shadow: 0 15px 30px rgba(16, 185, 129, 0.22); }

    .nav-toggle {
      display: none;
      width: 44px;
      height: 44px;
      border-radius: 14px;
      border: 1px solid var(--border);
      background: #fff;
      padding: 10px;
      cursor: pointer;
    }
    .nav-toggle span { display: block; height: 2px; margin: 6px 0; background: var(--dark); border-radius: 99px; transition: .22s ease; }

    .hero-section {
      position: relative;
      width: 100%;
      margin: 0;
      padding: 82px 24px 64px;
      overflow: hidden;
      background:
        linear-gradient(135deg, rgba(5, 14, 34, 0.98), rgba(20, 66, 165, 0.96) 55%, rgba(5, 150, 105, 0.92)),
        url("amar_thikanaa_icon.png");
      box-shadow: var(--shadow);
      color: #fff;
    }
    .hero-section::before {
      content: "";
      position: absolute;
      inset: 0;
      background:
        radial-gradient(circle at 10% 15%, rgba(255,255,255,.18), transparent 20%),
        radial-gradient(circle at 88% 16%, rgba(255,255,255,.14), transparent 21%),
        linear-gradient(115deg, rgba(255,255,255,.1), transparent 45%);
      pointer-events: none;
    }
    .hero-wrap {
      position: relative;
      width: min(1180px, 100%);
      margin: 0 auto;
      display: grid;
      grid-template-columns: 1.03fr .97fr;
      align-items: center;
      gap: 52px;
    }
    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 13px;
      border: 1px solid rgba(255,255,255,.24);
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.12);
      color: #dff7ff;
      font-size: 14px;
      font-weight: 800;
      letter-spacing: .2px;
    }
    .hero-copy h1 {
      margin: 22px 0 18px;
      color: #fff;
      font-size: clamp(38px, 4.4vw, 62px);
      line-height: 1.08;
      letter-spacing: -1.8px;
      max-width: 740px;
    }
    .typing-container {
      display: inline-block;
      min-height: 1.2em;
    }
    .typing-cursor {
      color: #38bdf8;
      font-weight: 200;
      animation: blink 0.8s infinite;
      margin-left: 2px;
    }
    @keyframes blink {
      0%, 100% { opacity: 1; }
      50% { opacity: 0; }
    }
    .hero-copy p {
      margin: 0;
      max-width: 640px;
      color: rgba(255,255,255,.86);
      font-size: 18px;
      line-height: 1.68;
    }
    .hero-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin: 30px 0 24px; }
    .hero-actions .btn { min-height: 52px; padding-inline: 24px; }
    .hero-actions .btn-primary { background: linear-gradient(135deg, #10b981, #059669); box-shadow: 0 18px 38px rgba(5, 150, 105, .35); }
    .hero-actions .btn-light { background: rgba(255,255,255,.14); color: #fff; border-color: rgba(255,255,255,.26); }
    .hero-search {
      max-width: 690px;
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 8px;
      padding: 8px;
      margin-top: 22px;
      background: rgba(255,255,255,.14);
      border: 1px solid rgba(255,255,255,.24);
      border-radius: 20px;
    }
    .hero-search input {
      width: 100%;
      border: 0;
      outline: 0;
      border-radius: 15px;
      padding: 15px 16px;
      color: var(--dark);
      background: #fff;
    }
    .hero-search button { border-radius: 15px; padding-inline: 22px; }
    .popular-tags { display: flex; flex-wrap: wrap; gap: 9px; margin-top: 16px; }
    .popular-tags a {
      padding: 7px 12px;
      border-radius: 999px;
      color: #e7f8ff;
      background: rgba(255,255,255,.12);
      border: 1px solid rgba(255,255,255,.18);
      font-size: 14px;
      font-weight: 700;
      transition: transform .2s ease, background .2s ease, border-color .2s ease;
    }
    .popular-tags a:hover { transform: translateY(-2px); background: rgba(255,255,255,.2); border-color: rgba(255,255,255,.34); }
    .hero-proof {
      display: flex;
      flex-wrap: wrap;
      gap: 10px 18px;
      margin-top: 18px;
      color: rgba(255,255,255,.84);
      font-size: 13px;
      font-weight: 700;
    }
    .hero-proof span { display: inline-flex; align-items: center; gap: 7px; }
    .hero-proof span::before {
      content: "✓";
      display: grid;
      place-items: center;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      color: #052e2b;
      background: #6ee7b7;
      font-size: 12px;
      font-weight: 900;
    }
    .metric-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; max-width: 655px; margin-top: 24px; }
    .metric-row div {
      padding: 16px;
      border-radius: 18px;
      background: rgba(255,255,255,.11);
      border: 1px solid rgba(255,255,255,.18);
    }
    .metric-row strong { display: block; color: #fff; font-family: Inter, sans-serif; font-size: 25px; line-height: 1; }
    .metric-row span { display: block; margin-top: 7px; color: rgba(255,255,255,.74); font-size: 14px; line-height: 1.35; }

    .hero-visual { position: relative; }
    .dashboard-card {
      position: relative;
      display: grid;
      grid-template-columns: 185px 1fr;
      min-height: 540px;
      padding: 12px;
      border: 1px solid rgba(255,255,255,.2);
      border-radius: 30px;
      background: rgba(255,255,255,.18);
      box-shadow: 0 40px 100px rgba(0,0,0,.3), inset 0 1px 0 rgba(255,255,255,.2);
      backdrop-filter: blur(14px);
      transform: rotate(1deg);
      transition: transform .35s ease, box-shadow .35s ease;
    }
    .dashboard-card:hover { transform: rotate(0deg) translateY(-5px); box-shadow: 0 48px 110px rgba(0,0,0,.34); }
    .dash-sidebar {
      border-radius: 22px;
      padding: 16px 12px;
      background: rgba(5, 18, 39, 0.82);
      color: rgba(255,255,255,.78);
    }
    .dash-logo { display: flex; gap: 8px; align-items: center; padding: 4px 4px 16px; margin-bottom: 10px; border-bottom: 1px solid rgba(255,255,255,.1); }
    .dash-logo img { width: 34px; height: 34px; border-radius: 11px; background: #fff; padding: 4px; }
    .dash-logo strong { display: block; font-size: 11px; color: #fff; line-height: 1.1; }
    .dash-logo small { display: block; font-size: 9px; color: rgba(255,255,255,.58); }
    .dash-sidebar a { display: flex; gap: 8px; align-items: center; padding: 10px; border-radius: 14px; font-size: 12px; font-weight: 700; margin-bottom: 6px; }
    .dash-sidebar a.active, .dash-sidebar a:hover { color: #fff; background: rgba(37, 99, 235, 0.95); }
    svg { width: 20px; height: 20px; flex: 0 0 auto; }
    .dash-content { padding: 12px; border-radius: 22px; background: #f8fbff; color: var(--dark); }
    .dash-topbar { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
    .search-box { flex: 1; display: flex; align-items: center; gap: 8px; padding: 8px 10px; border-radius: 16px; background: #fff; border: 1px solid var(--border); }
    .search-box input { width: 100%; border: 0; outline: 0; color: var(--dark); font-size: 12px; }
    .search-box button { border: 0; background: #eff6ff; color: var(--primary); border-radius: 12px; width: 34px; height: 34px; display: grid; place-items: center; cursor: pointer; }
    .login-btn { padding: 10px 12px; border-radius: 14px; background: var(--dark); color: #fff; font-size: 12px; font-weight: 800; white-space: nowrap; }
    .promo-banner {
      min-height: 175px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 22px;
      border-radius: 23px;
      color: #fff;
      background: linear-gradient(135deg, #2563eb, #0f766e);
      overflow: hidden;
    }
    .promo-banner h2 { margin: 0 0 6px; color: #fff; font-size: 27px; line-height: 1.04; letter-spacing: -.7px; }
    .promo-banner p { margin: 0 0 14px; color: rgba(255,255,255,.76); font-size: 13px; }
    .promo-banner a { display: inline-flex; padding: 8px 12px; border-radius: 999px; background: #fff; color: var(--primary); font-size: 12px; font-weight: 800; }
    .banner-phone { width: 118px; height: 150px; display: grid; place-items: center; border-radius: 26px; background: rgba(255,255,255,.14); border: 1px solid rgba(255,255,255,.2); transform: rotate(-8deg); }
    .banner-phone img { width: 68px; filter: drop-shadow(0 10px 20px rgba(0,0,0,.2)); }
    .dash-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-top: 13px; }
    .dash-grid article { position: relative; min-height: 104px; padding: 12px; border-radius: 18px; background: #fff; border: 1px solid var(--border); box-shadow: 0 8px 22px rgba(15,23,42,.05); }
    .dash-grid span { position: absolute; top: 10px; right: 12px; color: #cbd5e1; font: 800 14px Inter, sans-serif; }
    .dash-grid i, .service-card i, .feature-icon {
      width: 42px;
      height: 42px;
      display: grid;
      place-items: center;
      border-radius: 15px;
      margin-bottom: 10px;
    }
    .dash-grid strong { display: block; font-size: 13px; line-height: 1.2; color: var(--dark); }
    .dash-grid small { display: block; margin-top: 5px; color: var(--muted); font-size: 11px; }
    .blue { color: #2563eb; background: #dbeafe; }
    .green { color: #059669; background: #d1fae5; }
    .red { color: #dc2626; background: #fee2e2; }
    .violet { color: #7c3aed; background: #ede9fe; }
    .orange { color: #ea580c; background: #ffedd5; }
    .teal { color: #0f766e; background: #ccfbf1; }

    .floating-card {
      position: absolute;
      left: -22px;
      bottom: 26px;
      width: 210px;
      padding: 14px;
      border-radius: 20px;
      background: rgba(255,255,255,.95);
      color: var(--dark);
      box-shadow: 0 22px 55px rgba(0,0,0,.2);
      transform: rotate(-4deg);
    }
    .floating-card strong { display: block; font-size: 16px; }
    .floating-card span { display: block; margin-top: 5px; color: var(--muted); font-size: 13px; line-height: 1.35; }

    .network-stats-section { padding-top: 54px; }
    .network-stats-panel {
      position: relative;
      padding: 34px;
      border: 1px solid rgba(37, 99, 235, .12);
      border-radius: 30px;
      background:
        radial-gradient(circle at 8% 10%, rgba(37, 99, 235, .11), transparent 28%),
        radial-gradient(circle at 92% 90%, rgba(16, 185, 129, .12), transparent 30%),
        rgba(255, 255, 255, .88);
      box-shadow: var(--soft-shadow);
      overflow: hidden;
    }
    .network-stats-heading { display: flex; align-items: end; justify-content: space-between; gap: 22px; margin-bottom: 24px; }
    .network-stats-heading span { color: var(--primary); font-size: 14px; font-weight: 900; }
    .network-stats-heading h2 { margin: 5px 0 0; color: var(--dark); font-size: clamp(28px, 3vw, 42px); line-height: 1.15; }
    .network-stats-heading p { max-width: 470px; margin: 0; color: var(--muted); line-height: 1.65; }
    .network-stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
    .network-stat-card {
      --stat-color: #2563eb;
      position: relative;
      min-height: 178px;
      padding: 22px;
      border: 1px solid var(--border);
      border-radius: 22px;
      background: #fff;
      box-shadow: 0 12px 30px rgba(15, 23, 42, .07);
      overflow: hidden;
      opacity: 0;
      transform: translateY(20px) scale(.97);
      transition: opacity .5s ease, transform .5s ease, box-shadow .25s ease;
    }
    .network-stat-card.is-visible { opacity: 1; transform: translateY(0) scale(1); }
    .network-stat-card:hover { transform: translateY(-5px); box-shadow: 0 20px 42px rgba(15, 23, 42, .12); }
    .network-stat-card::after {
      content: "";
      position: absolute;
      right: -35px;
      bottom: -45px;
      width: 120px;
      height: 120px;
      border-radius: 50%;
      background: color-mix(in srgb, var(--stat-color) 12%, transparent);
    }
    .network-stat-card.shopkeepers { --stat-color: #10b981; }
    .network-stat-card.delivery { --stat-color: #f97316; }
    .network-stat-card.field-force { --stat-color: #7c3aed; }
    .network-stat-icon {
      width: 46px;
      height: 46px;
      display: grid;
      place-items: center;
      border-radius: 16px;
      color: #fff;
      background: var(--stat-color);
      font: 900 19px Inter, sans-serif;
      box-shadow: 0 10px 22px color-mix(in srgb, var(--stat-color) 28%, transparent);
    }
    .network-stat-card strong { display: block; margin-top: 18px; color: var(--dark); font: 900 36px/1 Inter, sans-serif; }
    .network-stat-card span { display: block; margin-top: 8px; color: #53627a; font-weight: 800; }
    .network-stats-status { min-height: 22px; margin: 15px 0 0; color: var(--muted); text-align: center; font-size: 14px; }

    .leaderboard-panel {
      position: relative;
      padding: 34px;
      border: 1px solid rgba(37, 99, 235, .12);
      border-radius: 30px;
      background: rgba(255, 255, 255, .88);
      box-shadow: var(--soft-shadow);
    }
    .leaderboard-heading { display: flex; flex-wrap: wrap; align-items: end; justify-content: space-between; gap: 18px; margin-bottom: 22px; }
    .leaderboard-heading span { color: var(--primary); font-size: 14px; font-weight: 900; }
    .leaderboard-heading h2 { margin: 5px 0 0; color: var(--dark); font-size: clamp(26px, 3vw, 38px); line-height: 1.15; }
    .leaderboard-district-select {
      padding: 12px 16px;
      border: 1px solid var(--border);
      border-radius: 14px;
      background: #fff;
      color: var(--dark);
      font-weight: 800;
      min-width: 220px;
    }
    .leaderboard-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .leaderboard-col h3 { margin: 0 0 14px; color: var(--dark); font-size: 19px; }
    .leaderboard-list { display: grid; gap: 8px; padding: 0; margin: 0; list-style: none; max-height: 560px; overflow-y: auto; }
    .leaderboard-row {
      display: grid;
      grid-template-columns: 34px 1fr auto;
      align-items: center;
      gap: 12px;
      padding: 11px 14px;
      border-radius: 14px;
      background: #fff;
      border: 1px solid var(--border);
    }
    .leaderboard-row.rank-1 { border-color: rgba(249, 115, 22, .45); background: linear-gradient(135deg, #fff7ed, #fff); }
    .leaderboard-row.rank-2 { border-color: rgba(100, 116, 139, .4); background: linear-gradient(135deg, #f8fafc, #fff); }
    .leaderboard-row.rank-3 { border-color: rgba(180, 83, 9, .35); background: linear-gradient(135deg, #fefce8, #fff); }
    .leaderboard-rank {
      width: 30px;
      height: 30px;
      display: grid;
      place-items: center;
      border-radius: 50%;
      background: #eff6ff;
      color: var(--primary);
      font: 900 13px Inter, sans-serif;
    }
    .leaderboard-row.rank-1 .leaderboard-rank { background: #f97316; color: #fff; }
    .leaderboard-row.rank-2 .leaderboard-rank { background: #64748b; color: #fff; }
    .leaderboard-row.rank-3 .leaderboard-rank { background: #b45309; color: #fff; }
    .leaderboard-name { min-width: 0; }
    .leaderboard-name strong { display: block; color: var(--dark); font-size: 14.5px; line-height: 1.25; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .leaderboard-name small { display: block; margin-top: 2px; color: var(--muted); font-size: 12px; }
    .leaderboard-amount { color: var(--secondary); font-weight: 900; font-size: 13.5px; white-space: nowrap; }
    .leaderboard-empty { padding: 22px; text-align: center; color: var(--muted); font-size: 14px; }

    @media (max-width: 900px) {
      .leaderboard-grid { grid-template-columns: 1fr; }
    }

    /* Team & Field Network Section */
    .team-network-section {
      position: relative;
      padding: 30px 0 0;
    }
    .team-panel {
      position: relative;
      padding: 36px 30px;
      border: 1px solid rgba(37, 99, 235, 0.14);
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.94);
      backdrop-filter: blur(12px);
      box-shadow: var(--soft-shadow);
    }
    .team-header {
      display: flex;
      flex-wrap: wrap;
      align-items: flex-end;
      justify-content: space-between;
      gap: 20px;
      margin-bottom: 26px;
    }
    .team-header .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: 999px;
      background: #eff6ff;
      color: var(--primary);
      font-size: 13px;
      font-weight: 800;
      letter-spacing: .02em;
    }
    .team-header h2 {
      margin: 8px 0 6px;
      color: var(--dark);
      font-size: clamp(26px, 3.2vw, 38px);
      font-weight: 900;
      line-height: 1.18;
    }
    .team-header p {
      margin: 0;
      color: var(--muted);
      font-size: 15.5px;
      max-width: 640px;
    }
    .team-controls-bar {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      padding: 16px 20px;
      margin-bottom: 26px;
      background: #f8faff;
      border: 1px solid rgba(37, 99, 235, 0.1);
      border-radius: 18px;
    }
    .team-role-tabs {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .team-tab-btn {
      padding: 8px 18px;
      border-radius: 999px;
      border: 1px solid rgba(23, 39, 64, 0.12);
      background: #fff;
      color: var(--text);
      font-weight: 800;
      font-size: 14px;
      cursor: pointer;
      transition: all .22s ease;
    }
    .team-tab-btn:hover {
      background: #eff6ff;
      color: var(--primary);
      border-color: var(--primary);
    }
    .team-tab-btn.active {
      background: linear-gradient(135deg, var(--primary), var(--primary-dark));
      color: #fff;
      border-color: transparent;
      box-shadow: 0 6px 16px rgba(37, 99, 235, 0.28);
    }
    .team-filter-inputs {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 10px;
      flex: 1;
      justify-content: flex-end;
    }
    .team-search-input {
      padding: 10px 16px;
      border: 1px solid var(--border);
      border-radius: 999px;
      background: #fff;
      font-size: 14px;
      min-width: 220px;
      outline: none;
      transition: border-color .2s ease;
    }
    .team-search-input:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }
    .team-district-select {
      padding: 10px 16px;
      border: 1px solid var(--border);
      border-radius: 999px;
      background: #fff;
      color: var(--dark);
      font-weight: 700;
      font-size: 14px;
      outline: none;
      cursor: pointer;
    }
    .team-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 20px;
    }
    .team-card {
      position: relative;
      display: flex;
      flex-direction: column;
      background: #ffffff;
      border: 1px solid rgba(23, 39, 64, 0.08);
      border-radius: 20px;
      padding: 22px 20px;
      box-shadow: 0 8px 24px rgba(15, 23, 42, 0.05);
      transition: transform .25s ease, box-shadow .25s ease, border-color .25s ease;
    }
    .team-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 16px 36px rgba(15, 23, 42, 0.12);
      border-color: rgba(37, 99, 235, 0.3);
    }
    .team-card-top {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 14px;
    }
    .team-avatar-box {
      position: relative;
      width: 72px;
      height: 72px;
      flex-shrink: 0;
    }
    .team-avatar-img {
      width: 100%;
      height: 100%;
      border-radius: 50%;
      object-fit: cover;
      border: 3px solid #fff;
      box-shadow: 0 8px 18px rgba(15, 23, 42, 0.16);
    }
    .team-avatar-fallback {
      width: 100%;
      height: 100%;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      font-weight: 900;
      color: #fff;
      box-shadow: 0 8px 18px rgba(37, 99, 235, 0.22);
    }
    .team-avatar-fallback.agent {
      background: linear-gradient(135deg, #2563eb, #7c3aed);
    }
    .team-avatar-fallback.field {
      background: linear-gradient(135deg, #10b981, #0f766e);
    }
    .team-verified-badge {
      position: absolute;
      bottom: -2px;
      right: -2px;
      width: 22px;
      height: 22px;
      background: #10b981;
      color: #fff;
      border: 2.5px solid #fff;
      border-radius: 50%;
      display: grid;
      place-items: center;
      font-size: 11px;
      font-weight: 900;
    }
    .team-info-header {
      flex: 1;
      min-width: 0;
    }
    .team-role-tag {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 3px 10px;
      border-radius: 999px;
      font-size: 11.5px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: .03em;
      margin-bottom: 4px;
    }
    .team-role-tag.agent {
      background: #eff6ff;
      color: #1d4ed8;
      border: 1px solid rgba(37, 99, 235, 0.2);
    }
    .team-role-tag.field {
      background: #ecfdf5;
      color: #047857;
      border: 1px solid rgba(16, 185, 129, 0.2);
    }
    .team-name {
      margin: 0;
      font-size: 17px;
      font-weight: 800;
      color: var(--dark);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .team-location {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 13px;
      color: var(--muted);
      margin-top: 2px;
    }
    .team-location svg {
      width: 14px;
      height: 14px;
      color: var(--primary);
      flex-shrink: 0;
    }
    .team-meta-box {
      background: #f8fafc;
      border-radius: 12px;
      padding: 10px 12px;
      margin: 10px 0 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    .team-meta-item {
      display: flex;
      flex-direction: column;
    }
    .team-meta-label {
      font-size: 11px;
      color: var(--muted);
      font-weight: 600;
    }
    .team-meta-value {
      font-size: 13.5px;
      font-weight: 800;
      color: var(--dark);
    }
    .team-meta-rating {
      color: #f59e0b;
      font-weight: 900;
      font-size: 13px;
      display: flex;
      align-items: center;
      gap: 3px;
    }
    .team-card-actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      margin-top: auto;
    }
    .team-btn-call {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 9px 12px;
      border-radius: 12px;
      background: #eff6ff;
      color: var(--primary);
      font-weight: 800;
      font-size: 13px;
      border: 1px solid rgba(37, 99, 235, 0.18);
      transition: all .2s ease;
      text-decoration: none;
    }
    .team-btn-call:hover {
      background: var(--primary);
      color: #fff;
    }
    .team-btn-whatsapp {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 9px 12px;
      border-radius: 12px;
      background: #ecfdf5;
      color: #059669;
      font-weight: 800;
      font-size: 13px;
      border: 1px solid rgba(16, 185, 129, 0.22);
      transition: all .2s ease;
      text-decoration: none;
    }
    .team-btn-whatsapp:hover {
      background: #10b981;
      color: #fff;
    }
    .team-join-cta {
      margin-top: 32px;
      background: linear-gradient(135deg, #071629 0%, #1e3a8a 100%);
      border-radius: 20px;
      padding: 24px 28px;
      color: #fff;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
    }
    .team-join-cta-text h4 {
      margin: 0 0 4px;
      font-size: 20px;
      font-weight: 800;
      color: #fff;
    }
    .team-join-cta-text p {
      margin: 0;
      color: #cbd5e1;
      font-size: 14.5px;
    }
    .team-join-cta-btn {
      padding: 12px 24px;
      border-radius: 999px;
      background: linear-gradient(135deg, #10b981, #059669);
      color: #fff;
      font-weight: 800;
      font-size: 15px;
      box-shadow: 0 10px 24px rgba(16, 185, 129, 0.35);
      border: 0;
      cursor: pointer;
      text-decoration: none;
      transition: transform .2s ease;
      white-space: nowrap;
    }
    .team-join-cta-btn:hover {
      transform: translateY(-2px);
    }

    .section { padding: 86px 0 0; }
    .section-heading { max-width: 720px; margin: 0 auto 34px; text-align: center; }
    .section-heading span {
      display: inline-flex;
      padding: 7px 13px;
      border-radius: 999px;
      background: #eff6ff;
      color: var(--primary);
      font-weight: 900;
      font-size: 14px;
    }
    .section-heading h2 { margin: 14px 0 12px; color: var(--dark); font-size: clamp(30px, 4vw, 48px); line-height: 1.12; letter-spacing: -.7px; }
    .section-heading p { margin: 0; color: var(--muted); font-size: 17px; line-height: 1.7; }

    .service-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
    .service-card {
      position: relative;
      min-height: 285px;
      padding: 26px;
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      background: rgba(255,255,255,.88);
      box-shadow: var(--soft-shadow);
      overflow: hidden;
      transition: transform .24s ease, box-shadow .24s ease, border-color .24s ease;
    }
    .service-card::after {
      content: "";
      position: absolute;
      right: -55px;
      top: -55px;
      width: 150px;
      height: 150px;
      border-radius: 50%;
      background: rgba(37, 99, 235, 0.07);
    }
    .service-card:hover { transform: translateY(-7px); box-shadow: 0 24px 60px rgba(15,23,42,.13); border-color: rgba(37,99,235,.25); }
    .service-card h3 { margin: 12px 0 9px; color: var(--dark); font-size: 24px; line-height: 1.2; }
    .service-card p { margin: 0 0 18px; color: var(--muted); line-height: 1.65; font-size: 16px; }
    .service-list { display: grid; gap: 7px; margin: 0 0 20px; padding: 0; list-style: none; }
    .service-list li { display: flex; align-items: flex-start; gap: 8px; color: #40516b; font-size: 15px; line-height: 1.42; }
    .service-list li::before { content: "✓"; display: inline-grid; place-items: center; width: 19px; height: 19px; border-radius: 50%; color: #fff; background: var(--secondary); font-size: 12px; font-weight: 900; margin-top: 1px; }
    .card-link { color: var(--primary); font-weight: 900; }

    .grocery-section {
      position: relative;
      isolation: isolate;
      padding-inline: 18px;
      background:
        radial-gradient(circle at 8% 8%, rgba(56,189,248,.24), transparent 28%),
        radial-gradient(circle at 92% 18%, rgba(167,139,250,.24), transparent 26%),
        radial-gradient(circle at 55% 100%, rgba(52,211,153,.2), transparent 34%),
        linear-gradient(145deg, #eff6ff 0%, #f5f3ff 44%, #ecfdf5 100%) !important;
      border: 1px solid rgba(255,255,255,.9) !important;
      box-shadow: 0 30px 90px rgba(30,64,175,.13) !important;
    }
    .grocery-section::before {
      content: "";
      position: absolute;
      inset: 0;
      z-index: -1;
      pointer-events: none;
      background: linear-gradient(115deg, rgba(255,255,255,.72), transparent 28%, rgba(255,255,255,.3) 53%, transparent 72%);
    }
    .grocery-section .section-heading > span {
      color: #fff;
      background: linear-gradient(135deg, #2563eb, #7c3aed 52%, #059669);
      box-shadow: 0 12px 30px rgba(79,70,229,.26), inset 0 1px 0 rgba(255,255,255,.45);
    }
    .grocery-showcase {
      display: grid;
      grid-template-columns: .88fr 1.12fr;
      gap: 22px;
      align-items: stretch;
    }
    .grocery-feature {
      min-height: 520px;
      position: sticky;
      top: 104px;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      overflow: hidden;
      padding: 30px;
      border-radius: 30px;
      color: #fff;
      background:
        linear-gradient(155deg, rgba(37,99,235,.2), rgba(109,40,217,.48) 45%, rgba(5,150,105,.88)),
        linear-gradient(180deg, rgba(7, 22, 41, .02), rgba(7, 22, 41, .84)),
        url("https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1000&q=80") center/cover;
      border: 1px solid rgba(255,255,255,.55);
      box-shadow: 0 30px 75px rgba(30,64,175,.25), inset 0 1px 0 rgba(255,255,255,.45);
    }
    .grocery-feature::before {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(115deg, rgba(255,255,255,.24), transparent 34%),
        radial-gradient(circle at 88% 10%, rgba(255,255,255,.32), transparent 24%);
    }
    .grocery-feature > * { position: relative; z-index: 1; }
    .grocery-feature span {
      width: fit-content;
      padding: 8px 13px;
      border-radius: 999px;
      color: #d1fae5;
      background: rgba(255, 255, 255, .14);
      font-size: 14px;
      font-weight: 900;
    }
    .grocery-feature h3 {
      max-width: 430px;
      margin: 16px 0 10px;
      color: #fff;
      font-size: clamp(30px, 3.4vw, 46px);
      line-height: 1.08;
    }
    .grocery-feature p {
      max-width: 440px;
      margin: 0;
      color: rgba(255, 255, 255, .82);
      font-size: 17px;
      line-height: 1.65;
    }
    .marketplace-benefits {
      display: grid;
      gap: 9px;
      margin: 20px 0 24px;
      padding: 0;
      list-style: none;
    }
    .marketplace-benefits li { display: flex; align-items: center; gap: 9px; color: rgba(255,255,255,.92); font-weight: 700; }
    .marketplace-benefits li::before { content: "✓"; display: grid; place-items: center; width: 22px; height: 22px; border-radius: 50%; color: #064e3b; background: #a7f3d0; font-size: 12px; font-weight: 900; }
    .marketplace-actions { display: flex; flex-wrap: wrap; gap: 10px; }
    .marketplace-actions .btn { font-size: 14px; }
    .smart-bazar-trustbar {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      margin: 0 0 24px;
    }
    .smart-bazar-trustbar div {
      padding: 15px 17px;
      border: 1px solid #dbe7f3;
      border-radius: 16px;
      background: linear-gradient(145deg, rgba(255,255,255,.96), rgba(239,246,255,.78));
      box-shadow: 0 16px 38px rgba(37,99,235,.1), inset 0 1px 0 #fff;
      transition: transform .24s ease, box-shadow .24s ease;
    }
    .smart-bazar-trustbar div:nth-child(2) { background: linear-gradient(145deg, rgba(255,255,255,.97), rgba(245,243,255,.86)); }
    .smart-bazar-trustbar div:nth-child(3) { background: linear-gradient(145deg, rgba(255,255,255,.97), rgba(236,253,245,.86)); }
    .smart-bazar-trustbar div:hover { transform: translateY(-5px); box-shadow: 0 22px 48px rgba(79,70,229,.16), inset 0 1px 0 #fff; }
    .smart-bazar-trustbar strong { display: block; color: #0f172a; font-size: 15px; }
    .smart-bazar-trustbar span { display: block; margin-top: 3px; color: #64748b; font-size: 13px; }
    .grocery-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 16px;
    }
    .product-card {
      overflow: hidden;
      border: 1px solid var(--border);
      border-radius: 22px;
      background: linear-gradient(145deg, rgba(255,255,255,.98), rgba(248,250,252,.9));
      box-shadow: 0 18px 42px rgba(30,64,175,.1), inset 0 1px 0 #fff;
      transition: transform .24s ease, box-shadow .24s ease;
    }
    .product-card:hover {
      transform: translateY(-6px);
      border-color: rgba(99,102,241,.34);
      box-shadow: 0 28px 62px rgba(79,70,229,.18), 0 0 0 1px rgba(255,255,255,.8) inset;
    }
    .product-card img {
      width: 100%;
      aspect-ratio: 4 / 3;
      object-fit: cover;
      background: #eef2f7;
    }
    .product-info { padding: 18px; }
    .product-info strong {
      display: block;
      color: var(--dark);
      font-size: 21px;
      line-height: 1.2;
    }
    .product-info span {
      display: block;
      margin-top: 7px;
      color: var(--muted);
      font-weight: 700;
      line-height: 1.45;
    }
    .product-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 14px;
    }
    .product-meta b {
      padding: 7px 10px;
      border-radius: 999px;
      color: var(--primary);
      background: #eff6ff;
      font-size: 13px;
      line-height: 1;
    }

    .trust-strip {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 14px;
      margin-top: 24px;
    }
    .trust-item {
      display: flex;
      gap: 12px;
      align-items: center;
      padding: 18px;
      border-radius: 20px;
      background: #fff;
      border: 1px solid var(--border);
      box-shadow: 0 10px 28px rgba(15,23,42,.06);
    }
    .trust-item strong { display: block; color: var(--dark); line-height: 1.2; font-size: 16px; }
    .trust-item small { display: block; margin-top: 4px; color: var(--muted); line-height: 1.35; }

    .split-section {
      display: grid;
      grid-template-columns: .92fr 1.08fr;
      gap: 28px;
      align-items: center;
      padding: 38px;
      border-radius: var(--radius-lg);
      background: linear-gradient(135deg, #08162d, #12326d);
      color: #fff;
      box-shadow: var(--shadow);
      overflow: hidden;
    }
    .split-section h2 { margin: 0 0 15px; color: #fff; font-size: clamp(30px, 4vw, 48px); line-height: 1.1; }
    .split-section p { margin: 0; color: rgba(255,255,255,.75); line-height: 1.75; font-size: 17px; }
    .step-list { display: grid; gap: 14px; margin-top: 24px; }
    .step-item { display: grid; grid-template-columns: 44px 1fr; gap: 13px; align-items: start; padding: 16px; border-radius: 20px; background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.12); }
    .step-number { width: 44px; height: 44px; display: grid; place-items: center; border-radius: 16px; background: #fff; color: var(--primary); font: 900 18px Inter, sans-serif; }
    .step-item strong { display: block; color: #fff; font-size: 18px; }
    .step-item span { display: block; margin-top: 5px; color: rgba(255,255,255,.7); line-height: 1.5; }
    .process-panel { border-radius: 26px; padding: 20px; background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.14); }
    .process-card { padding: 20px; border-radius: 22px; background: #fff; color: var(--dark); margin-bottom: 13px; }
    .process-card:last-child { margin-bottom: 0; }
    .process-card small { color: var(--primary); font-weight: 900; text-transform: uppercase; letter-spacing: .5px; }
    .process-card h3 { margin: 7px 0 8px; font-size: 21px; }
    .process-card p { color: var(--muted); font-size: 15px; line-height: 1.6; }

    .audience-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 14px; }
    .audience-card {
      padding: 22px 18px;
      border-radius: 22px;
      border: 1px solid var(--border);
      background: #fff;
      text-align: center;
      box-shadow: 0 13px 32px rgba(15,23,42,.06);
      transition: .24s ease;
    }
    .audience-card:hover { transform: translateY(-6px); }
    .audience-card i { width: 56px; height: 56px; display: grid; place-items: center; margin: 0 auto 13px; border-radius: 20px; }
    .audience-card strong { display: block; color: var(--dark); font-size: 18px; line-height: 1.2; }
    .audience-card span { display: block; margin-top: 8px; color: var(--muted); font-size: 14px; line-height: 1.45; }

    .highlight-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
    .highlight-card {
      min-height: 282px;
      padding: 28px;
      border-radius: var(--radius-md);
      color: #fff;
      overflow: hidden;
      position: relative;
      box-shadow: var(--soft-shadow);
    }
    .highlight-card::after { content: ""; position: absolute; right: -70px; bottom: -70px; width: 190px; height: 190px; border-radius: 50%; background: rgba(255,255,255,.13); }
    .highlight-card span { font: 900 48px Inter, sans-serif; color: rgba(255,255,255,.28); }
    .highlight-card h3 { margin: 22px 0 10px; color: #fff; font-size: 24px; line-height: 1.2; }
    .highlight-card p { margin: 0; color: rgba(255,255,255,.78); line-height: 1.7; font-size: 16px; }
    .lead-card { background: linear-gradient(135deg, #2563eb, #1d4ed8); }
    .spotlight-card { background: linear-gradient(135deg, #059669, #0f766e); }
    .trust-card { background: linear-gradient(135deg, #7c3aed, #4f46e5); }

    .faq-wrap { display: grid; grid-template-columns: .85fr 1.15fr; gap: 28px; align-items: start; }
    .faq-side { position: sticky; top: 105px; padding: 28px; border-radius: var(--radius-md); background: #fff; border: 1px solid var(--border); box-shadow: var(--soft-shadow); }
    .faq-side h2 { margin: 0 0 10px; color: var(--dark); font-size: 34px; line-height: 1.12; }
    .faq-side p { margin: 0 0 20px; color: var(--muted); line-height: 1.7; }
    .faq-list { display: grid; gap: 12px; }
    .faq-item { border-radius: 19px; background: #fff; border: 1px solid var(--border); box-shadow: 0 10px 26px rgba(15,23,42,.05); overflow: hidden; }
    .faq-question { width: 100%; display: flex; align-items: center; justify-content: space-between; gap: 15px; padding: 18px 20px; border: 0; background: transparent; color: var(--dark); font-weight: 900; text-align: left; cursor: pointer; }
    .faq-question span { width: 28px; height: 28px; display: grid; place-items: center; border-radius: 50%; background: #eff6ff; color: var(--primary); flex: 0 0 auto; }
    .faq-answer { display: none; padding: 0 20px 18px; color: var(--muted); line-height: 1.65; }
    .faq-item.open .faq-answer { display: block; }
    .faq-item.open .faq-question span { background: var(--primary); color: #fff; }

    .contact-section {
      display: grid;
      grid-template-columns: .92fr 1.08fr;
      gap: 24px;
      align-items: stretch;
      padding: 36px;
      border-radius: 34px;
      background: #fff;
      box-shadow: var(--shadow);
      border: 1px solid var(--border);
    }
    .contact-copy { padding: 16px; }
    .contact-copy span { display: inline-flex; padding: 7px 13px; border-radius: 999px; background: #ecfdf5; color: #059669; font-weight: 900; }
    .contact-copy h2 { margin: 16px 0 12px; color: var(--dark); font-size: clamp(30px, 4vw, 46px); line-height: 1.1; }
    .contact-copy p { margin: 0; color: var(--muted); line-height: 1.75; font-size: 17px; }
    .contact-points { display: grid; gap: 10px; margin-top: 22px; }
    .contact-points div { display: flex; align-items: center; gap: 10px; color: #40516b; font-weight: 700; }
    .contact-points div::before { content: "✓"; width: 24px; height: 24px; display: grid; place-items: center; border-radius: 50%; background: #dcfce7; color: #059669; font-weight: 900; }
    .contact-direct { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 20px; }
    .contact-direct a {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 15px;
      border-radius: 999px;
      background: #fff;
      border: 1px solid var(--border);
      color: var(--dark);
      font-weight: 800;
      font-size: 14px;
      box-shadow: 0 8px 20px rgba(15, 23, 42, .05);
      transition: transform .2s ease, box-shadow .2s ease;
    }
    .contact-direct a:hover { transform: translateY(-2px); box-shadow: 0 14px 28px rgba(15, 23, 42, .1); }
    .contact-direct a.whatsapp { color: #15803d; }
    .contact-direct a.email { color: var(--primary); }
    .footer-contact { display: grid; gap: 12px; }
    .footer-contact a {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 13px 14px;
      border: 1px solid rgba(255,255,255,.1);
      border-radius: 14px;
      color: rgba(255,255,255,.9);
      background: rgba(255,255,255,.055);
      font-weight: 700;
      transition: transform .2s ease, border-color .2s ease, background .2s ease;
    }
    .footer-contact a:hover { color: #fff; transform: translateY(-2px); border-color: rgba(110,231,183,.45); background: rgba(255,255,255,.1); }
    .footer-contact-icon {
      display: grid;
      place-items: center;
      width: 38px;
      height: 38px;
      flex: 0 0 auto;
      border-radius: 11px;
      color: #fff;
      background: linear-gradient(135deg, #2563eb, #1d4ed8);
    }
    .footer-contact a.whatsapp .footer-contact-icon { background: linear-gradient(135deg, #25d366, #128c7e); }
    .footer-contact-text { display: grid; gap: 2px; min-width: 0; }
    .footer-contact-text small { color: rgba(255,255,255,.55); font-size: 11px; text-transform: uppercase; letter-spacing: .7px; }
    .footer-contact-text strong { overflow-wrap: anywhere; color: #fff; font-size: 14px; }
    .lead-form { display: grid; gap: 14px; padding: 24px; border-radius: 26px; background: #f8fbff; border: 1px solid var(--border); }
    .lead-form label { display: grid; gap: 7px; color: var(--dark); font-weight: 800; }
    .lead-form input, .lead-form select, .lead-form textarea {
      width: 100%;
      border: 1px solid rgba(15,23,42,.12);
      border-radius: 15px;
      background: #fff;
      color: var(--dark);
      outline: 0;
      padding: 14px 15px;
      transition: .2s ease;
    }
    .lead-form textarea { min-height: 110px; resize: vertical; }
    .lead-form input:focus, .lead-form select:focus, .lead-form textarea:focus { border-color: rgba(37,99,235,.55); box-shadow: 0 0 0 4px rgba(37,99,235,.12); }
    .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .form-message { margin: 0; min-height: 24px; color: #059669; font-weight: 800; }

    .final-cta { position: relative; overflow: hidden; padding: 44px; border-radius: 34px; color: #fff; background: linear-gradient(135deg, #2563eb, #0f172a); box-shadow: var(--shadow); }
    .final-cta::after { content: ""; position: absolute; width: 250px; height: 250px; border-radius: 50%; right: -80px; top: -90px; background: rgba(255,255,255,.13); }
    .final-cta-inner { position: relative; display: flex; align-items: center; justify-content: space-between; gap: 24px; }
    .final-cta h2 { margin: 0 0 10px; color: #fff; font-size: clamp(28px, 4vw, 44px); line-height: 1.12; }
    .final-cta p { margin: 0; max-width: 650px; color: rgba(255,255,255,.76); line-height: 1.7; }

    .site-footer {
      position: relative;
      margin-top: 80px;
      padding: 64px 0 0;
      overflow: hidden;
      color: #d6e4ff;
      background: linear-gradient(145deg, #061224, #0a1f38 58%, #07352f);
    }
    .site-footer::before {
      content: "";
      position: absolute;
      width: 420px;
      height: 420px;
      right: -150px;
      top: -210px;
      border-radius: 50%;
      background: rgba(16,185,129,.13);
      filter: blur(4px);
    }
    .footer-inner {
      position: relative;
      width: min(1180px, calc(100% - 32px));
      margin: 0 auto;
      display: grid;
      grid-template-columns: 1.2fr .72fr 1fr;
      gap: 56px;
      align-items: start;
      padding-bottom: 48px;
    }
    .footer-brand-lockup { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; }
    .footer-brand-lockup img { width: 54px; height: 54px; padding: 6px; border-radius: 16px; background: #fff; }
    .footer-brand-lockup strong { display: block; color: #fff; font-size: 23px; line-height: 1.1; }
    .footer-brand-lockup small { color: #6ee7b7; font-weight: 700; }
    .footer-description { max-width: 410px; margin: 0; color: rgba(255,255,255,.66); line-height: 1.75; }
    .footer-column h3 { margin: 0 0 18px; color: #fff; font-size: 16px; }
    .footer-links { display: grid; gap: 11px; }
    .footer-links a { width: fit-content; color: rgba(255,255,255,.7); font-weight: 700; }
    .footer-links a::before { content: "›"; margin-right: 8px; color: #6ee7b7; }
    .footer-bottom {
      position: relative;
      width: min(1180px, calc(100% - 32px));
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      gap: 16px;
      padding: 20px 0 24px;
      border-top: 1px solid rgba(255,255,255,.1);
      color: rgba(255,255,255,.5);
      font-size: 13px;
    }

    .hero-copy > * {
      opacity: 0;
      animation: hero-rise .75s cubic-bezier(.22, 1, .36, 1) forwards;
    }
    .hero-copy > :nth-child(1) { animation-delay: .08s; }
    .hero-copy > :nth-child(2) { animation-delay: .18s; }
    .hero-copy > :nth-child(3) { animation-delay: .28s; }
    .hero-copy > :nth-child(4) { animation-delay: .38s; }
    .hero-copy > :nth-child(5) { animation-delay: .48s; }
    .hero-copy > :nth-child(6) { animation-delay: .58s; }
    .hero-copy > :nth-child(7) { animation-delay: .68s; }
    .hero-visual {
      opacity: 0;
      animation: hero-visual-in .9s .3s cubic-bezier(.22, 1, .36, 1) forwards;
    }
    .dashboard-card { animation: dashboard-float 5.5s 1.3s ease-in-out infinite; }
    .floating-card { animation: floating-card 4.4s 1.1s ease-in-out infinite; }
    .hero-section::before { animation: hero-glow 9s ease-in-out infinite alternate; }
    .popular-tags a, .footer-links a { transition: transform .2s ease, color .2s ease, background .2s ease; }
    .popular-tags a:hover { transform: translateY(-3px); background: rgba(255,255,255,.22); }
    .footer-links a:hover { color: #fff; transform: translateY(-2px); }
    .metric-row div, .trust-item, .process-card, .faq-item {
      transition: transform .28s ease, box-shadow .28s ease, border-color .28s ease;
    }
    .metric-row div:hover { transform: translateY(-5px); background: rgba(255,255,255,.17); }
    .trust-item:hover, .process-card:hover, .faq-item:hover {
      transform: translateY(-4px);
      border-color: rgba(37,99,235,.24);
      box-shadow: 0 18px 42px rgba(15,23,42,.1);
    }
    .reveal {
      opacity: 0;
      transform: translateY(34px) scale(.985);
      transition:
        opacity .72s cubic-bezier(.22, 1, .36, 1),
        transform .72s cubic-bezier(.22, 1, .36, 1);
      transition-delay: var(--reveal-delay, 0ms);
    }
    .reveal.reveal-left { transform: translateX(-42px); }
    .reveal.reveal-right { transform: translateX(42px); }
    .reveal.is-visible { opacity: 1; transform: none; }

    @keyframes hero-rise {
      from { opacity: 0; transform: translateY(24px); }
      to { opacity: 1; transform: none; }
    }
    @keyframes hero-visual-in {
      from { opacity: 0; transform: translateX(45px) scale(.95); }
      to { opacity: 1; transform: none; }
    }
    @keyframes dashboard-float {
      0%, 100% { translate: 0 0; }
      50% { translate: 0 -10px; }
    }
    @keyframes floating-card {
      0%, 100% { translate: 0 0; }
      50% { translate: 0 -8px; }
    }
    @keyframes hero-glow {
      from { transform: scale(1); opacity: .8; }
      to { transform: scale(1.08); opacity: 1; }
    }

        .live-chat { position: fixed; right: 22px; bottom: 22px; z-index: 60; font-family: "Anek Bangla", sans-serif; }
    .chat-launcher { animation: pulseGlow 2s infinite;  display: flex; align-items: center; gap: 10px; border: 0; border-radius: 999px; padding: 12px 14px 12px 18px; color: #fff; background: linear-gradient(135deg, #11998e, #38ef7d); box-shadow: 0 15px 35px rgba(56, 239, 125, 0.4); cursor: pointer; transition: 0.3s; }
    @keyframes pulseGlow {
      0% { box-shadow: 0 0 0 0 rgba(56, 239, 125, 0.7); transform: scale(1); }
      70% { box-shadow: 0 0 0 15px rgba(56, 239, 125, 0); transform: scale(1.05); }
      100% { box-shadow: 0 0 0 0 rgba(56, 239, 125, 0); transform: scale(1); }
    }
    .chat-launcher:hover { transform: translateY(-3px); box-shadow: 0 20px 40px rgba(56, 239, 125, 0.6); }
    .chat-launcher span { font-weight: 900; }
    .chat-launcher strong { width: 30px; height: 30px; display: grid; place-items: center; border-radius: 50%; background: rgba(255,255,255,.22); }
    
    .chat-panel { display: none; width: min(360px, calc(100vw - 28px)); margin-bottom: 12px; overflow: hidden; border-radius: 24px; background: rgba(255, 255, 255, 0.9); box-shadow: 0 28px 80px rgba(0, 0, 0, 0.2); backdrop-filter: blur(15px); border: 1px solid rgba(255,255,255,0.4); }
    .live-chat.open .chat-panel { display: block; animation: slideUp 0.3s ease-out; }
    @keyframes slideUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
    
    .chat-header { display: flex; justify-content: space-between; gap: 12px; align-items: center; padding: 20px; color: #fff; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .chat-header strong { display: block; font-size: 1.1rem; }
    .chat-header small { display: block; color: rgba(255,255,255,.8); font-size: 0.85rem; }
    .chat-close { border: 0; background: rgba(255,255,255,.2); color: #fff; width: 34px; height: 34px; border-radius: 50%; cursor: pointer; font-size: 20px; transition: 0.3s; }
    .chat-close:hover { background: rgba(255,255,255,.4); transform: rotate(90deg); }
    
    .chat-messages { padding: 20px; height: 300px; max-height: 50vh; overflow-y: auto; background: rgba(248, 251, 255, 0.6); display: flex; flex-direction: column; gap: 12px; }
    .chat-messages::-webkit-scrollbar { width: 6px; }
    .chat-messages::-webkit-scrollbar-thumb { background: rgba(118, 75, 162, 0.3); border-radius: 10px; }
    
    .chat-bubble { width: fit-content; max-width: 85%; padding: 12px 16px; border-radius: 18px; line-height: 1.4; font-size: 0.95rem; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
    .chat-bubble.support { background: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%); color: #333; border-bottom-left-radius: 5px; display: flex; gap: 10px; align-items: flex-end; }
    .chat-bubble.user { margin-left: auto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; border-bottom-right-radius: 5px; }
    .chat-bubble.connecting {
      display: grid;
      gap: 5px;
      padding: 14px 16px;
      border: 1px solid #bfdbfe;
      color: #1e3a8a;
      background: linear-gradient(135deg, #eff6ff, #eef2ff);
      box-shadow: 0 8px 24px rgba(37,99,235,.1);
    }
    .chat-bubble.connecting strong { color: #1d4ed8; font-size: 14px; }
    .chat-bubble.connecting span { color: #475569; font-size: 13px; line-height: 1.5; }
    .connecting-dots { display: inline-flex; gap: 4px; margin-left: 5px; vertical-align: middle; }
    .connecting-dots i { width: 5px; height: 5px; border-radius: 50%; background: #2563eb; animation: connecting-dot 1.15s infinite ease-in-out; }
    .connecting-dots i:nth-child(2) { animation-delay: .16s; }
    .connecting-dots i:nth-child(3) { animation-delay: .32s; }
    @keyframes connecting-dot { 0%, 70%, 100% { opacity: .3; transform: translateY(0); } 35% { opacity: 1; transform: translateY(-3px); } }
    
    .chat-avatar { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; box-shadow: 0 2px 5px rgba(0,0,0,0.2); }
    .chat-quick { display: flex; gap: 8px; flex-wrap: wrap; padding: 10px 20px 15px; background: rgba(248, 251, 255, 0.6); }
    .chat-quick button { border: 1px solid rgba(118, 75, 162, 0.3); background: rgba(255,255,255,0.8); color: #764ba2; padding: 6px 14px; border-radius: 999px; font-weight: bold; cursor: pointer; transition: 0.2s; font-size: 0.85rem; }
    .chat-quick button:hover { background: #764ba2; color: #fff; }
    
    .chat-form { display: flex; gap: 10px; padding: 15px; border-top: 1px solid rgba(0,0,0,0.05); background: #fff; }
    .chat-form input { flex: 1; border: 1px solid rgba(0,0,0,0.1); background: rgba(240, 240, 245, 0.5); outline: 0; border-radius: 20px; padding: 12px 15px; transition: 0.3s; }
    .chat-form input:focus { border-color: #764ba2; background: #fff; box-shadow: 0 0 0 3px rgba(118, 75, 162, 0.1); }
    .chat-form button { border: 0; border-radius: 50%; width: 45px; height: 45px; display: grid; place-items: center; color: #fff; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-weight: 900; cursor: pointer; transition: 0.3s; box-shadow: 0 4px 15px rgba(118, 75, 162, 0.4); }
    .chat-form button:hover { transform: scale(1.05); }
    .chat-form button:disabled { opacity: 0.5; cursor: not-allowed; }

    @media (max-width: 1080px) {
      .hero-wrap, .split-section, .contact-section, .faq-wrap { grid-template-columns: 1fr; }
      .network-stats-grid { grid-template-columns: repeat(2, 1fr); }
      .dashboard-card { max-width: 720px; margin: 0 auto; transform: none; }
      .audience-grid { grid-template-columns: repeat(3, 1fr); }
      .trust-strip { grid-template-columns: repeat(2, 1fr); }
      .faq-side { position: static; }
    }

    @media (max-width: 900px) {
      .nav-toggle { display: block; }
      .nav-links {
        position: absolute;
        left: 17px;
        right: 17px;
        top: 78px;
        display: none;
        flex-direction: column;
        align-items: stretch;
        padding: 12px;
        border-radius: 20px;
        background: #fff;
        box-shadow: var(--soft-shadow);
        border: 1px solid var(--border);
      }
      .site-header.menu-open .nav-links { display: flex; }
      .nav-links a { border-radius: 14px; }
      .top-login-btn { display: none; }
      .hero-section { padding: 44px 20px 28px; border-radius: 28px; }
      .service-grid, .highlight-grid { grid-template-columns: repeat(2, 1fr); }
      .grocery-showcase { grid-template-columns: 1fr; }
      .smart-bazar-trustbar { grid-template-columns: 1fr; }
      .grocery-feature { position: relative; top: auto; min-height: 420px; }
      .form-grid { grid-template-columns: 1fr; }
      .final-cta-inner { flex-direction: column; align-items: flex-start; }
      .footer-inner { grid-template-columns: 1fr 1fr; gap: 36px; }
      .footer-brand { grid-column: 1 / -1; }
    }

    @media (max-width: 680px) {
      .container, .navbar, .footer-inner { width: 100%; padding: 0 16px; }
      .navbar { min-height: 70px; }
      .brand { min-width: 0; }
      .brand-text img { max-width: 136px; }
      .brand-text small { display: none; }
      .hero-section { width: min(100% - 20px, 100%); margin-top: 18px; }
      .hero-copy h1 { font-size: 37px; letter-spacing: -.8px; }
      .hero-copy p { font-size: 17px; }
      .hero-proof { gap: 10px; }
      .hero-search { grid-template-columns: 1fr; }
      .hero-search button { width: 100%; }
      .metric-row, .service-grid, .highlight-grid, .trust-strip, .audience-grid, .grocery-grid { grid-template-columns: 1fr; }
      .grocery-feature { min-height: 360px; padding: 24px; border-radius: 24px; }
      .dashboard-card { grid-template-columns: 1fr; min-height: auto; }
      .dash-sidebar { display: none; }
      .dash-topbar { flex-direction: column; align-items: stretch; }
      .dash-grid { grid-template-columns: repeat(2, 1fr); }
      .promo-banner { flex-direction: column; align-items: flex-start; }
      .floating-card { position: static; width: 100%; margin-top: 14px; transform: none; }
      .hero-visual { display: none; }
      .split-section, .contact-section, .final-cta { padding: 24px; border-radius: 26px; }
      .network-stats-panel { padding: 24px 18px; border-radius: 24px; }
      .network-stats-heading { align-items: flex-start; flex-direction: column; }
      .network-stats-grid { grid-template-columns: 1fr; }
      .section { padding-top: 62px; }
      .live-chat { right: 12px; bottom: 12px; }
      .site-footer { padding-top: 46px; }
      .footer-inner { grid-template-columns: 1fr; gap: 32px; }
      .footer-brand { grid-column: auto; }
      .footer-bottom { flex-direction: column; text-align: center; align-items: center; }
    }

    @media (prefers-reduced-motion: reduce) {
      html { scroll-behavior: auto; }
      *, *::before, *::after {
        animation-duration: .01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: .01ms !important;
      }
      .reveal, .reveal.reveal-left, .reveal.reveal-right {
        opacity: 1;
        transform: none;
      }
    }
    /* Smart Solutions Banner (Hubuhu Redesign) */
    .smart-solutions-banner {
      background: #fdfdfd;
      border: none;
      border-top: 1px solid #ddd;
      border-bottom: 1px solid #ddd;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      margin: 40px 0;
      width: 100%;
      position: relative;
      overflow: hidden;
      font-family: 'Anek Bangla', sans-serif;
    }
    .ss-banner-header {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 30px;
      background: #fdfdfd;
    }
    .ss-logo-block {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    .ss-logo-icon {
      background-color: #1a7138;
      width: 70px;
      height: 70px;
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 5px;
    }
    .ss-logo-icon svg { width: 40px; height: 40px; }
    .ss-logo-text { color: #1a7138; font-size: 16px; font-weight: 800; text-align: center; line-height: 1.1; }
    .ss-banner-header h3 { margin: 0; font-size: 32px; font-weight: 800; color: #1a4a38; line-height: 1.2; }
    .ss-banner-header h3 span { color: #333; font-size: 22px; font-weight: 600; display: block; margin-top: 8px;}
    
    .ss-banner-body { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; padding: 0 15px 30px; }
    .ss-col { background: #fff; position: relative; display: flex; flex-direction: column; }
    
    /* Top Image Box */
    .ss-image-container { position: relative; width: 100%; height: 220px; border-radius: 4px; overflow: hidden; background: #e0e0e0; margin-bottom: 20px;}
    .ss-image-container img { width: 100%; height: 100%; object-fit: cover; }
    
    /* Colored Tags Overlapping */
    .ss-tab {
      position: absolute;
      top: -15px;
      left: -5px;
      z-index: 10;
      padding: 8px 16px;
      color: white;
      font-weight: bold;
      font-size: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
      border-radius: 20px 20px 20px 0;
      box-shadow: 2px 4px 10px rgba(0,0,0,0.2);
    }
    .ss-tab svg { width: 20px; height: 20px; }
    .ss-tab-red { background: #b71c1c; }
    .ss-tab-blue { background: #1565c0; }
    .ss-tab-green { background: #1b5e20; }
    
    /* Speech Bubble */
    .ss-bubble {
      position: absolute;
      bottom: 20px;
      right: 20px;
      background: rgba(255, 255, 255, 0.95);
      padding: 10px 15px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 600;
      max-width: 160px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.15);
      border: 1px solid #eee;
    }
    .ss-bubble::after {
      content: '';
      position: absolute;
      top: 50%;
      left: -8px;
      border-width: 8px 8px 8px 0;
      border-style: solid;
      border-color: transparent white transparent transparent;
      transform: translateY(-50%);
    }
    .ss-bubble-red { color: #b71c1c; }
    .ss-bubble-blue { color: #1565c0; }
    .ss-bubble-green { color: #1b5e20; }
    
    /* Bottom Section */
    .ss-bottom-section { display: flex; flex-direction: row; align-items: stretch; background: #f4f6f8; padding: 15px; border-radius: 8px; flex-grow: 1; border: 1px solid #e2e8f0; }
    
    /* Phone Mockup */
    .ss-app-mockup {
      width: 130px;
      background: white;
      border-radius: 20px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      overflow: hidden;
      border: 6px solid #111;
      margin-right: 15px;
      flex-shrink: 0;
      display: flex;
      flex-direction: column;
      position: relative;
    }
    .ss-app-mockup::before {
      content: '';
      position: absolute;
      top: 0; left: 50%; transform: translateX(-50%);
      width: 40%; height: 12px;
      background: #111;
      border-bottom-left-radius: 6px;
      border-bottom-right-radius: 6px;
      z-index: 2;
    }
    .ss-app-mockup-header { padding: 12px 8px 8px; color: white; font-size: 11px; font-weight: bold; position: relative; z-index: 1; }
    .ss-mockup-body { padding: 8px; font-size: 9px; color: #444; background: #fff; flex-grow: 1;}
    .ss-bg-red { background: #b71c1c; }
    .ss-bg-blue { background: #1565c0; }
    .ss-bg-green { background: #1b5e20; }
    
    .ss-inner-list { list-style: none; padding: 0; margin: 0; }
    .ss-inner-list li { margin-bottom: 6px; display: flex; align-items: flex-start; border-bottom: 1px solid #f0f0f0; padding-bottom: 4px; line-height: 1.2; }
    .ss-inner-list li:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
    .ss-inner-list li svg { width: 10px; height: 10px; margin-right: 4px; flex-shrink: 0; margin-top: 1px; }
    
    /* Features List */
    .ss-feature-list { list-style: none; padding: 0; margin: 0; font-size: 13px; font-weight: 600; display: flex; flex-direction: column; justify-content: center; }
    .ss-feature-list li { margin-bottom: 10px; display: flex; align-items: flex-start; line-height: 1.3; }
    .ss-feature-list li svg { width: 16px; height: 16px; margin-right: 8px; flex-shrink: 0; margin-top: 2px; }
    .ss-text-red { color: #b71c1c; }
    .ss-text-blue { color: #1565c0; }
    .ss-text-green { color: #1b5e20; }
    
    /* Footer Banner */
    .ss-banner-footer {
      background: #1a7138;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px 30px;
      color: white;
      flex-wrap: wrap;
      gap: 15px;
    }
    .ss-footer-left { display: flex; align-items: center; gap: 15px; }
    .ss-footer-left-icon {
      background: white; width: 45px; height: 45px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
    }
    .ss-footer-left-icon svg { width: 28px; height: 28px; }
    .ss-footer-left h4 { margin: 0; font-size: 22px; font-weight: bold; }
    .ss-footer-left p { margin: 0; font-size: 14px; opacity: 0.9; }
    .ss-footer-right { display: flex; gap: 15px; }
    .ss-footer-right img { height: 40px; cursor: pointer; border-radius: 6px; border: 1px solid rgba(255,255,255,0.2); }
    
    @media (max-width: 991px) {
      .ss-banner-body { grid-template-columns: 1fr; }
      .ss-bottom-section { flex-direction: row; }
      .ss-banner-header { flex-direction: column; text-align: center; }
      .ss-footer-left { flex-direction: column; text-align: center; }
      .ss-banner-footer { justify-content: center; }
    }

    /* SOS Showcase Section */
    .sos-showcase-section {
      margin: 60px auto;
      background: #090e17; /* Very dark background */
      border-radius: 24px;
      padding: 60px 40px;
      font-family: "Anek Bangla", "Inter", sans-serif;
      overflow: hidden;
      display: flex;
      justify-content: center;
      gap: 40px;
      box-shadow: inset 0 0 100px rgba(0,0,0,0.8);
      animation: fadeIn 1s ease-out;
    }
    
    .sos-phone-mockup {
      width: 320px;
      height: 660px;
      background: #111827;
      border-radius: 40px;
      border: 6px solid #374151;
      position: relative;
      overflow: hidden;
      box-shadow: 0 20px 50px rgba(0,0,0,0.5), inset 0 0 4px rgba(255,255,255,0.2);
      display: flex;
      flex-direction: column;
      color: #fff;
    }
    .sos-phone-notch {
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 120px;
      height: 25px;
      background: #374151;
      border-radius: 0 0 15px 15px;
      z-index: 10;
    }
    .sos-phone-content {
      flex: 1;
      overflow-y: auto;
      padding: 40px 15px 80px;
      scrollbar-width: none;
    }
    .sos-phone-content::-webkit-scrollbar { display: none; }
    
    /* Phone 1 */
    .sos-app-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
      color: #e5e7eb;
    }
    .sos-user-profile {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 14px;
      font-weight: 600;
    }
    .sos-user-profile img { width: 34px; height: 34px; border-radius: 50%; border: 2px solid #374151;}
    
    .sos-hero-card {
      background: linear-gradient(135deg, #dc2626, #991b1b);
      border-radius: 20px;
      padding: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;
      box-shadow: 0 10px 20px rgba(220, 38, 38, 0.3);
      position: relative;
      overflow: hidden;
    }
    .sos-hero-card::after {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      background: linear-gradient(180deg, rgba(255,255,255,0.1), transparent);
      pointer-events: none;
    }
    .sos-hero-card h2 { margin: 0; font-size: 22px; font-weight: 800; line-height: 1.2; }
    .sos-hero-card p { margin: 5px 0 0; font-size: 12px; opacity: 0.9; }
    .sos-hero-icon { width: 60px; filter: drop-shadow(0 4px 6px rgba(0,0,0,0.3)); }
    
    .sos-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    .sos-card {
      border-radius: 16px;
      padding: 15px 10px;
      text-align: center;
      position: relative;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
      box-shadow: inset 0 2px 5px rgba(255,255,255,0.15), 0 5px 15px rgba(0,0,0,0.4);
      transition: transform 0.2s;
      cursor: pointer;
    }
    .sos-card:active { transform: scale(0.95); }
    .sos-card.red { background: linear-gradient(135deg, #ef4444, #b91c1c); }
    .sos-card.blue { background: linear-gradient(135deg, #3b82f6, #1d4ed8); }
    .sos-card.green { background: linear-gradient(135deg, #10b981, #047857); }
    .sos-card.purple { background: linear-gradient(135deg, #8b5cf6, #5b21b6); }
    .sos-card.orange { background: linear-gradient(135deg, #f97316, #c2410c); }
    .sos-card.teal { background: linear-gradient(135deg, #14b8a6, #0f766e); }
    .sos-card.pink { background: linear-gradient(135deg, #ec4899, #be185d); }
    .sos-card.darkblue { background: linear-gradient(135deg, #2563eb, #1e40af); }
    
    .sos-card-icon {
      width: 48px;
      height: 48px;
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(255,255,255,0.2);
      box-shadow: inset 0 2px 4px rgba(255,255,255,0.3), 0 4px 8px rgba(0,0,0,0.2);
      font-size: 18px;
      font-weight: 900;
      color: #fff;
    }
    .sos-card h4 { margin: 0; font-size: 13px; font-weight: 700; color: #fff; text-shadow: 0 1px 2px rgba(0,0,0,0.5); }
    .sos-card p { margin: 0; font-size: 10px; color: rgba(255,255,255,0.8); }
    
    .sos-bottom-nav {
      position: absolute;
      bottom: 0; left: 0; right: 0;
      height: 65px;
      background: #0f172a;
      border-top: 1px solid #1e293b;
      display: flex;
      justify-content: space-around;
      align-items: center;
      padding: 0 10px;
      z-index: 20;
    }
    .sos-nav-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      font-size: 10px;
      color: #64748b;
      gap: 4px;
      cursor: pointer;
    }
    .sos-nav-item.active { color: #f8fafc; }
    .sos-nav-center {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: linear-gradient(135deg, #10b981, #047857);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-top: -30px;
      box-shadow: 0 5px 15px rgba(16, 185, 129, 0.4);
      border: 4px solid #111827;
      color: #fff;
      cursor: pointer;
    }

    /* Phone 2: Alert */
    .sos-alert-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 30px;
      color: #f1f5f9;
    }
    .sos-alert-header h3 { margin: 0; font-size: 18px; font-weight: 700; }
    
    .sos-big-button-wrapper {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-bottom: 30px;
    }
    .sos-big-button {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      background: radial-gradient(circle at 30% 30%, #ff6b6b, #dc2626, #7f1d1d);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 36px;
      font-weight: 900;
      color: #fff;
      box-shadow: inset -5px -5px 15px rgba(0,0,0,0.5), inset 5px 5px 15px rgba(255,255,255,0.4), 0 0 30px rgba(220, 38, 38, 0.6);
      border: 6px solid #450a0a;
      text-shadow: 0 2px 4px rgba(0,0,0,0.5);
      animation: pulse-sos 2s infinite;
      cursor: pointer;
    }
    .sos-big-button:active { transform: scale(0.95); }
    @keyframes pulse-sos {
      0% { box-shadow: 0 0 0 0 rgba(220, 38, 38, 0.5), inset -5px -5px 15px rgba(0,0,0,0.5), inset 5px 5px 15px rgba(255,255,255,0.4); }
      70% { box-shadow: 0 0 0 20px rgba(220, 38, 38, 0), inset -5px -5px 15px rgba(0,0,0,0.5), inset 5px 5px 15px rgba(255,255,255,0.4); }
      100% { box-shadow: 0 0 0 0 rgba(220, 38, 38, 0), inset -5px -5px 15px rgba(0,0,0,0.5), inset 5px 5px 15px rgba(255,255,255,0.4); }
    }
    .sos-big-button-wrapper p {
      margin: 20px 0 0;
      font-size: 13px;
      text-align: center;
      color: #9ca3af;
      line-height: 1.4;
    }
    
    .sos-location-card {
      background: #1e293b;
      border-radius: 16px;
      padding: 15px;
      margin-bottom: 25px;
      border: 1px solid #334155;
    }
    .sos-card-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
      font-size: 13px;
      font-weight: 700;
      color: #e2e8f0;
    }
    .sos-live-tag {
      background: #059669;
      color: #fff;
      padding: 3px 8px;
      border-radius: 12px;
      font-size: 10px;
      display: flex;
      align-items: center;
      gap: 4px;
    }
    .sos-map-box {
      height: 100px;
      background: #334155 url('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=400&q=80') center/cover;
      border-radius: 10px;
      margin-bottom: 12px;
      position: relative;
      overflow: hidden;
    }
    .sos-map-pin {
      position: absolute;
      top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      width: 16px; height: 16px;
      background: #3b82f6;
      border-radius: 50%;
      border: 3px solid #fff;
      box-shadow: 0 0 10px rgba(0,0,0,0.5);
    }
    .sos-location-card p { margin: 0; font-size: 11px; color: #94a3b8; }
    
    .sos-contacts-section h4 { margin: 0 0 12px; font-size: 13px; font-weight: 700; color: #e2e8f0; }
    .sos-contact-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
    }
    .sos-contact-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .sos-contact-info img { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; }
    .sos-contact-info h5 { margin: 0; font-size: 13px; font-weight: 600; color: #f1f5f9; }
    .sos-contact-info p { margin: 0; font-size: 11px; color: #94a3b8; }
    .sos-send-btn {
      background: linear-gradient(135deg, #ef4444, #b91c1c);
      color: #fff;
      border: none;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 5px;
      cursor: pointer;
      box-shadow: 0 2px 5px rgba(220, 38, 38, 0.4);
    }
    
    .sos-action-btn {
      width: 100%;
      background: linear-gradient(135deg, #7c3aed, #4c1d95);
      color: #fff;
      border: none;
      padding: 14px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      cursor: pointer;
      margin-top: 20px;
      box-shadow: 0 5px 15px rgba(124, 58, 237, 0.3);
    }

    @media (max-width: 900px) {
      .sos-showcase-section { flex-direction: column; align-items: center; padding: 40px 20px; }
      .sos-phone-mockup { width: 100%; max-width: 340px; }
    }
    /* Grocery Section */
    .grocery-section {
      margin: 60px auto;
      background: #fcfcfc;
      border-radius: 24px;
      overflow: hidden;
      font-family: "Anek Bangla", "Inter", sans-serif;
      box-shadow: 0 15px 40px rgba(0,0,0,0.06);
      border: 1px solid #eee;
      animation: fadeIn 1s ease-out;
    }
    
    .grocery-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 40px;
      background: #fff;
    }
    .grocery-header-left {
      display: flex;
      gap: 25px;
      align-items: flex-start;
    }
    .grocery-header-left img.logo {
      height: 90px;
      background: #166534;
      padding: 15px;
      border-radius: 20px;
    }
    .grocery-header-text h2 {
      color: #166534;
      font-size: 38px;
      font-weight: 800;
      margin: 0 0 5px 0;
      line-height: 1.1;
    }
    .grocery-header-text h3 {
      color: #111;
      font-size: 24px;
      font-weight: 700;
      margin: 0 0 10px 0;
    }
    .grocery-header-text p {
      color: #4b5563;
      font-size: 18px;
      font-weight: 500;
      margin: 0;
    }
    .grocery-header-right img {
      height: 140px;
      border-radius: 16px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.1);
    }
    
    .grocery-steps {
      display: flex;
      align-items: stretch;
      gap: 15px;
      padding: 0 30px 40px;
      background: #fff;
      overflow-x: auto;
    }
    .grocery-step {
      flex: 1;
      min-width: 220px;
      background: #f8fafc;
      border-radius: 16px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      border: 1px solid #e2e8f0;
      transition: transform 0.3s;
    }
    .grocery-step:hover { transform: translateY(-5px); box-shadow: 0 15px 30px rgba(0,0,0,0.05); }
    .grocery-step-header {
      background: #166534;
      color: #fff;
      padding: 12px;
      font-weight: 700;
      font-size: 15px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .grocery-step-header .step-num {
      background: #fff;
      color: #166534;
      width: 24px;
      height: 24px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      font-weight: 900;
    }
    .grocery-step-img-box {
      position: relative;
      height: 200px;
      background: #e2e8f0;
      overflow: hidden;
    }
    .grocery-step-img-box img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: center;
    }
    .grocery-step-text {
      padding: 15px;
      font-size: 14px;
      font-weight: 600;
      color: #334155;
      text-align: center;
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      line-height: 1.4;
    }
    .grocery-step-arrow {
      display: flex;
      align-items: center;
      justify-content: center;
      color: #166534;
      padding: 0 5px;
    }
    .grocery-step-arrow svg {
      width: 32px; height: 32px;
      background: #dcfce7;
      border-radius: 50%;
      padding: 6px;
    }
    
    .grocery-mini-phone {
      position: absolute;
      bottom: -15px;
      right: 15px;
      width: 100px;
      background: #fff;
      border-radius: 12px;
      border: 4px solid #111;
      box-shadow: 0 10px 20px rgba(0,0,0,0.2);
      font-size: 9px;
      transform: rotate(-5deg);
      overflow: hidden;
      z-index: 2;
    }
    
    .grocery-trust-banner {
      background: #166534;
      color: #fff;
      text-align: center;
      padding: 20px;
      font-size: 26px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 15px;
      border-radius: 0 0 24px 24px;
      margin: 0 30px 30px;
      box-shadow: 0 10px 20px rgba(22, 101, 52, 0.2);
    }
    
    .grocery-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 30px 40px;
      background: #f0fdf4;
      border-top: 2px solid #dcfce7;
      flex-wrap: wrap;
      gap: 25px;
    }
    .grocery-footer-feature {
      display: flex;
      align-items: center;
      gap: 15px;
    }
    .grocery-footer-feature svg {
      width: 36px;
      height: 36px;
      color: #166534;
    }
    .grocery-footer-feature h5 {
      margin: 0 0 4px;
      font-size: 16px;
      font-weight: 700;
      color: #111;
    }
    .grocery-footer-feature p {
      margin: 0;
      font-size: 14px;
      color: #555;
    }
    .grocery-footer-download {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    
    @media (max-width: 1100px) {
      .grocery-header { flex-direction: column; text-align: center; gap: 20px; }
      .grocery-header-left { flex-direction: column; align-items: center; }
      .grocery-steps { flex-direction: column; }
      .grocery-step-arrow { transform: rotate(90deg); margin: 10px 0; }
      .grocery-footer { flex-direction: column; text-align: center; }
      .grocery-footer-download { flex-direction: column; }
    }
    /* Tutor Section */
    .tutor-section {
      margin: 60px auto;
      background: #fdfdfd;
      border-radius: 24px;
      overflow: hidden;
      font-family: "Anek Bangla", "Inter", sans-serif;
      box-shadow: 0 15px 40px rgba(0,0,0,0.06);
      border: 1px solid #eee;
    }
    .tutor-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 40px;
      background: #fff;
    }
    .tutor-header-logo img {
      height: 80px;
      background: #166534;
      padding: 10px;
      border-radius: 16px;
    }
    .tutor-header-center {
      text-align: center;
      flex: 1;
      padding: 0 20px;
    }
    .tutor-header-center h2 {
      color: #166534;
      font-size: 36px;
      font-weight: 800;
      margin: 0 0 10px 0;
    }
    .tutor-header-center p {
      color: #333;
      font-size: 20px;
      margin: 0;
      font-weight: 500;
    }
    .tutor-header-right {
      text-align: center;
    }
    .tutor-header-right svg {
      width: 50px;
      height: 50px;
      color: #166534;
      margin-bottom: 5px;
    }
    .tutor-header-right div {
      font-weight: 700;
      font-size: 14px;
      line-height: 1.2;
    }

    .tutor-main {
      position: relative;
      background: #f0f4f2;
      padding: 40px 20px;
      display: flex;
      justify-content: center;
      align-items: stretch;
      gap: 20px;
    }
    .tutor-side {
      flex: 1;
      display: flex;
      flex-direction: column;
      z-index: 2;
    }
    .tutor-side-box {
      background: #166534;
      color: #fff;
      padding: 15px 25px;
      border-radius: 12px;
      display: inline-block;
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 20px;
      align-self: flex-start;
      box-shadow: 0 5px 15px rgba(22,101,52,0.2);
    }
    .tutor-side.right .tutor-side-box {
      align-self: flex-end;
    }
    .tutor-features {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .tutor-features li {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 12px;
      font-size: 16px;
      font-weight: 600;
      color: #222;
      background: rgba(255,255,255,0.7);
      padding: 10px 15px;
      border-radius: 10px;
    }
    .tutor-features li svg {
      width: 24px;
      height: 24px;
      color: #166534;
      flex-shrink: 0;
    }
    .tutor-img {
      margin-top: auto;
      width: 100%;
      height: 250px;
      object-fit: cover;
      border-radius: 16px;
      box-shadow: 0 10px 20px rgba(0,0,0,0.1);
    }
    .tutor-center-phone {
      width: 320px;
      position: relative;
      z-index: 5;
      flex-shrink: 0;
    }
    .tutor-phone-mockup {
      background: #fff;
      border: 12px solid #111;
      border-radius: 40px;
      height: 600px;
      overflow: hidden;
      box-shadow: 0 20px 50px rgba(0,0,0,0.3);
      position: relative;
    }
    .tutor-phone-notch {
      position: absolute;
      top: 0; left: 50%;
      transform: translateX(-50%);
      width: 120px; height: 25px;
      background: #111;
      border-radius: 0 0 15px 15px;
      z-index: 10;
    }
    .tutor-phone-header {
      padding: 35px 15px 10px;
      background: #fff;
      border-bottom: 1px solid #eee;
    }
    .tutor-search-bar {
      background: #f5f5f5;
      padding: 10px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 10px;
      color: #777;
      font-size: 13px;
      margin-top: 15px;
      margin-bottom: 10px;
    }
    .tutor-list {
      padding: 10px;
      background: #fdfdfd;
      height: calc(100% - 150px);
      overflow-y: auto;
    }
    .tutor-card {
      background: #fff;
      border: 1px solid #eee;
      border-radius: 10px;
      padding: 12px;
      display: flex;
      gap: 12px;
      margin-bottom: 12px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.02);
    }
    .tutor-card img {
      width: 50px;
      height: 50px;
      border-radius: 50%;
      object-fit: cover;
    }
    .tutor-card-info h4 { margin: 0 0 3px; font-size: 14px; font-weight: 700; color: #111; }
    .tutor-card-info p { margin: 0; font-size: 11px; color: #555; }
    .tutor-card-info .rate { margin-top: 5px; font-size: 12px; font-weight: 700; color: #166534; }
    
    .tutor-action-banners {
      display: flex;
      justify-content: space-between;
      padding: 30px;
      background: #f0f4f2;
      position: relative;
    }
    .tutor-action-banner {
      background: #166534;
      color: #fff;
      padding: 20px 30px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      gap: 15px;
      width: 45%;
      box-shadow: 0 10px 20px rgba(22,101,52,0.2);
      transition: transform 0.3s;
      cursor: pointer;
    }
    .tutor-action-banner:hover { transform: translateY(-3px); }
    .tutor-action-banner svg {
      width: 40px; height: 40px; flex-shrink: 0;
    }
    .tutor-action-banner h4 {
      margin: 0 0 5px; font-size: 20px; font-weight: 700;
    }
    .tutor-action-banner p {
      margin: 0; font-size: 14px; opacity: 0.9;
    }
    
    .tutor-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 30px 40px;
      background: #f0fdf4;
      border-top: 2px solid #dcfce7;
      flex-wrap: wrap;
      gap: 25px;
    }
    .tutor-footer-feature {
      display: flex;
      align-items: center;
      gap: 15px;
    }
    .tutor-footer-feature svg {
      width: 36px;
      height: 36px;
      color: #166534;
    }
    .tutor-footer-feature h5 {
      margin: 0 0 4px;
      font-size: 16px;
      font-weight: 700;
      color: #111;
    }
    .tutor-footer-feature p {
      margin: 0;
      font-size: 14px;
      color: #555;
    }
    .tutor-footer-download {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    @media (max-width: 1100px) {
      .tutor-main { flex-direction: column; align-items: center; gap: 40px; }
      .tutor-header { flex-direction: column; gap: 20px; text-align: center; }
      .tutor-side.right .tutor-side-box { align-self: center; }
      .tutor-side-box { align-self: center; }
      .tutor-action-banners { flex-direction: column; gap: 20px; align-items: center; }
      .tutor-action-banner { width: 100%; max-width: 400px; }
      .tutor-footer { flex-direction: column; text-align: center; }
      .tutor-footer-feature { justify-content: center; }
    }
    /* Verify Section */
    .verify-section {
      margin: 60px auto;
      background: #fff;
      border-radius: 24px;
      overflow: hidden;
      font-family: "Anek Bangla", "Inter", sans-serif;
      box-shadow: 0 15px 40px rgba(0,0,0,0.06);
      border: 1px solid #eee;
    }
    .verify-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 30px 40px;
      background: #f8fbfb;
      border-bottom: 2px solid #eef2f2;
    }
    .verify-header-logo { text-align: center; }
    .verify-header-logo img { height: 60px; background: #166534; padding: 10px; border-radius: 12px; margin-bottom: 5px; }
    .verify-header-logo div { font-size: 12px; font-weight: 600; color: #555; }
    .verify-header-center { text-align: center; flex: 1; padding: 0 20px; }
    .verify-header-center h2 { color: #1e3a8a; font-size: 40px; font-weight: 800; margin: 0 0 5px 0; letter-spacing: -0.5px; }
    .verify-header-center p { color: #333; font-size: 20px; margin: 0; font-weight: 600; }
    .verify-header-right { display: flex; align-items: center; gap: 10px; color: #1e3a8a; }
    .verify-header-right svg { width: 40px; height: 40px; }
    .verify-header-right div { font-weight: 700; font-size: 14px; line-height: 1.3; }

    .verify-main {
      position: relative;
      background: url('https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1200&q=80') center/cover no-repeat;
      padding: 60px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .verify-main::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(255,255,255,0.7);
    }
    .verify-side {
      position: relative;
      z-index: 2;
      flex: 1;
    }
    .verify-side.left {
      display: flex;
      justify-content: flex-start;
      padding-left: 40px;
    }
    .verify-speech-bubble {
      background: #fff;
      padding: 20px;
      border-radius: 50%;
      width: 200px;
      height: 200px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      font-weight: 700;
      font-size: 18px;
      color: #166534;
      box-shadow: 0 10px 25px rgba(0,0,0,0.1);
      border: 4px solid #166534;
    }
    .verify-side.right {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      padding-right: 40px;
    }
    .verify-features-box {
      background: rgba(255,255,255,0.9);
      padding: 25px;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      max-width: 350px;
      backdrop-filter: blur(5px);
      border: 1px solid #ddd;
    }
    .verify-features-box h3 {
      background: #1e3a8a;
      color: #fff;
      margin: -25px -25px 20px -25px;
      padding: 15px;
      border-radius: 16px 16px 0 0;
      font-size: 20px;
      text-align: center;
    }
    .verify-features-box ul {
      list-style: none;
      padding: 0; margin: 0;
    }
    .verify-features-box li {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 15px;
      font-weight: 600;
      color: #333;
    }
    .verify-features-box li svg { width: 20px; height: 20px; color: #1e3a8a; flex-shrink: 0; }

    .verify-center-phone {
      position: relative;
      z-index: 5;
      width: 340px;
      flex-shrink: 0;
      margin: 0 20px;
    }
    .verify-phone-mockup {
      background: #fff;
      border: 12px solid #111;
      border-radius: 40px;
      height: 680px;
      overflow: hidden;
      box-shadow: 0 25px 50px rgba(0,0,0,0.4);
      position: relative;
      display: flex;
      flex-direction: column;
    }
    .verify-phone-notch {
      position: absolute;
      top: 0; left: 50%;
      transform: translateX(-50%);
      width: 120px; height: 25px;
      background: #111;
      border-radius: 0 0 15px 15px;
      z-index: 10;
    }
    .verify-phone-header {
      background: #1e3a8a;
      color: #fff;
      padding: 40px 15px 15px;
      text-align: center;
      font-weight: 700;
      font-size: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
    }
    .verify-phone-header span { position: absolute; left: 15px; }
    .verify-phone-body {
      padding: 15px;
      flex: 1;
      overflow-y: auto;
      font-size: 11px;
    }
    .verify-phone-product {
      display: flex;
      gap: 10px;
      margin-bottom: 15px;
      border-bottom: 1px solid #eee;
      padding-bottom: 10px;
    }
    .verify-phone-product img { width: 60px; height: 60px; object-fit: contain; }
    .verify-phone-product-info h4 { margin: 0 0 3px; font-size: 13px; font-weight: 700; }
    .verify-phone-product-info p { margin: 0; color: #555; line-height: 1.4; }
    .verify-phone-checklist {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .verify-phone-checkitem {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid #f5f5f5;
      padding-bottom: 5px;
    }
    .verify-phone-checkitem div { display: flex; align-items: center; gap: 5px; font-weight: 600; color: #444; }
    .verify-phone-checkitem svg { width: 14px; height: 14px; color: #166534; }
    .verify-phone-checkitem span { color: #666; text-align: right; font-size: 10px; }
    .verify-phone-safe-banner {
      background: #f0fdf4;
      border: 1px solid #dcfce7;
      color: #166534;
      padding: 10px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 10px;
      margin-top: 15px;
      font-weight: 700;
      text-align: center;
      font-size: 12px;
    }

    .verify-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      padding: 40px;
      background: #fff;
      border-bottom: 2px solid #f0f0f0;
    }
    .verify-grid-item {
      display: flex;
      align-items: flex-start;
      gap: 15px;
    }
    .verify-grid-item svg { width: 40px; height: 40px; color: #1e3a8a; flex-shrink: 0; }
    .verify-grid-item h5 { margin: 0 0 5px; font-size: 16px; font-weight: 700; color: #1e3a8a; }
    .verify-grid-item p { margin: 0; font-size: 12px; color: #555; line-height: 1.4; }

    .verify-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 40px;
      background: #fdfdfd;
      flex-wrap: wrap;
      gap: 20px;
    }
    .verify-process {
      display: flex;
      align-items: center;
      gap: 15px;
    }
    .verify-process-badge {
      background: #166534;
      color: #fff;
      padding: 10px 20px;
      border-radius: 30px;
      font-weight: 700;
      font-size: 16px;
      white-space: nowrap;
    }
    .verify-process-steps {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .verify-step-item {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .verify-step-item svg { width: 32px; height: 32px; padding: 5px; border: 1px solid #ddd; border-radius: 8px; color: #1e3a8a; }
    .verify-step-item div { font-size: 12px; font-weight: 600; line-height: 1.2; color: #444; max-width: 100px;}
    .verify-step-arrow { color: #166534; font-weight: bold; }

    @media (max-width: 1200px) {
      .verify-main { flex-direction: column; gap: 40px; }
      .verify-side.left { justify-content: center; padding: 0; }
      .verify-side.right { align-items: center; padding: 0; }
      .verify-speech-bubble { border-radius: 20px; height: auto; padding: 20px; width: auto; max-width: 300px; }
      .verify-grid { grid-template-columns: repeat(2, 1fr); }
      .verify-header { flex-direction: column; text-align: center; gap: 20px; }
      .verify-footer { flex-direction: column; align-items: center; text-align: center; }
      .verify-process { flex-direction: column; }
      .verify-process-steps { flex-wrap: wrap; justify-content: center; }
    }
    /* Secure Deal Section */
    .secure-section {
      margin: 60px auto;
      background: #f8f9fa;
      border-radius: 24px;
      overflow: hidden;
      font-family: "Anek Bangla", "Inter", sans-serif;
      box-shadow: 0 15px 40px rgba(0,0,0,0.06);
      border: 1px solid #eee;
    }
    .secure-header {
      text-align: center;
      padding: 40px 20px 20px;
    }
    .secure-header-title {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 15px;
      margin-bottom: 15px;
    }
    .secure-header-title svg {
      width: 60px; height: 60px;
      color: #0b224c;
    }
    .secure-header-title h2 {
      margin: 0; font-size: 48px; font-weight: 800; color: #0b224c;
      display: flex; flex-direction: column; align-items: flex-start; line-height: 1.1;
    }
    .secure-header-title h2 span {
      font-size: 32px; color: #166534;
    }
    .secure-header-subtitle {
      background: #0b224c;
      color: #fff;
      display: inline-block;
      padding: 10px 30px;
      border-radius: 30px;
      font-size: 20px;
      font-weight: 600;
    }

    .secure-main {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 40px 40px;
      position: relative;
    }
    .secure-person {
      display: flex;
      flex-direction: column;
      align-items: center;
      width: 180px;
    }
    .secure-person img {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      object-fit: cover;
      border: 5px solid #166534;
      margin-bottom: 15px;
      background: #fff;
      box-shadow: 0 10px 20px rgba(0,0,0,0.1);
    }
    .secure-person-label {
      background: #0b224c;
      color: #fff;
      padding: 8px 30px;
      border-radius: 30px;
      font-size: 16px;
      font-weight: 700;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
      margin-top: -30px;
      z-index: 5;
      position: relative;
    }

    .secure-flow {
      flex: 1;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0 20px;
    }
    .secure-step {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      position: relative;
      width: 120px;
    }
    .secure-step-number {
      background: #166534;
      color: #fff;
      width: 24px; height: 24px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 14px;
      position: absolute;
      top: -10px;
      z-index: 5;
    }
    .secure-step-icon {
      background: #fff;
      width: 90px; height: 90px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 3px solid #0b224c;
      margin-bottom: 15px;
      position: relative;
      box-shadow: 0 5px 15px rgba(0,0,0,0.05);
    }
    .secure-step-icon svg { width: 40px; height: 40px; color: #0b224c; }
    .secure-step-check {
      position: absolute;
      bottom: -5px; right: -5px;
      background: #166534;
      color: #fff;
      border-radius: 50%;
      width: 24px; height: 24px;
      display: flex; align-items: center; justify-content: center;
    }
    .secure-step p {
      margin: 0; font-size: 14px; font-weight: 700; color: #333; line-height: 1.3;
    }
    .secure-step p span { color: #166534; }
    .secure-arrow {
      color: #0b224c;
      font-size: 24px;
      font-weight: bold;
    }

    .secure-banner {
      background: #0b224c;
      color: #fff;
      padding: 25px 40px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .secure-banner-left {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .secure-banner-shield {
      border: 2px solid #fff;
      border-radius: 12px 12px 25px 25px;
      width: 50px; height: 60px;
      display: flex; align-items: center; justify-content: center;
      background: #166534;
    }
    .secure-banner-shield svg { width: 30px; height: 30px; }
    .secure-banner-text h3 { margin: 0 0 5px; font-size: 24px; font-weight: 800; }
    .secure-banner-text p { margin: 0; font-size: 16px; opacity: 0.9; }
    .secure-banner-right {
      text-align: right;
    }
    .secure-banner-right p { margin: 0 0 5px; font-size: 16px; font-weight: 700; }
    .secure-stars {
      display: flex;
      gap: 5px;
      color: #facc15;
    }
    .secure-stars svg { width: 24px; height: 24px; fill: currentColor; }

    .secure-footer {
      background: #fff;
      display: flex;
      justify-content: space-around;
      padding: 20px;
      border-top: 1px solid #eee;
      flex-wrap: wrap;
      gap: 15px;
    }
    .secure-footer-item {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 700;
      color: #0b224c;
      font-size: 15px;
    }
    .secure-footer-item-icon {
      background: #0b224c;
      color: #fff;
      width: 28px; height: 28px;
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
    }
    .secure-footer-item-icon.shield { border-radius: 6px 6px 12px 12px; }
    .secure-footer-item-icon svg { width: 16px; height: 16px; }

    @media (max-width: 1100px) {
      .secure-main { flex-direction: column; gap: 30px; }
      .secure-flow { flex-wrap: wrap; justify-content: center; gap: 20px; }
      .secure-arrow { display: none; }
      .secure-banner { flex-direction: column; text-align: center; gap: 20px; }
      .secure-banner-left { flex-direction: column; }
    }
  
    /* New Billboard Layout CSS */
    .ss-billboard-layout .ss-bottom-section {
      display: flex;
      flex-direction: row;
      align-items: center;
      background: #f8f9fa;
      margin: 15px;
      border-radius: 12px;
      padding: 10px;
    }
    .ss-billboard-layout .ss-app-mockup {
      width: 140px;
      min-width: 140px;
      margin: 0;
      border: 3px solid #333;
      border-radius: 12px;
      border-bottom: none;
      box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    }
    .ss-billboard-layout .ss-app-mockup-header {
      padding: 8px;
      font-size: 10px;
      border-radius: 9px 9px 0 0;
    }
    .ss-billboard-layout .ss-mockup-body {
      padding: 5px;
      background: #f4f4f4;
      min-height: 120px;
    }
    .ss-prop-card {
      background: #fff;
      border-radius: 6px;
      padding: 4px;
      margin-bottom: 5px;
      display: flex;
      flex-direction: row;
      gap: 5px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .ss-prop-img {
      width: 30px;
      height: 30px;
      border-radius: 4px;
      background-size: cover;
      background-position: center;
    }
    .ss-prop-details {
      display: flex;
      flex-direction: column;
      font-size: 8px;
      line-height: 1.1;
      color: #555;
    }
    .ss-prop-details strong { font-size: 9px; color: #111; }
    .ss-prop-details .price { font-weight: bold; color: #d32f2f; }
    
    .ss-inner-list { list-style: none; padding: 5px; margin: 0; }
    .ss-inner-list li { font-size: 9px; display: flex; align-items: center; gap: 4px; margin-bottom: 8px; color: #333; font-weight: 500; }
    .ss-inner-list svg { width: 12px; height: 12px; }

    .ss-billboard-layout .ss-feature-list {
      flex: 1;
      padding: 10px 10px 10px 15px;
      background: transparent;
    }
    .ss-billboard-layout .ss-feature-list li {
      font-size: 11px;
      margin-bottom: 10px;
    }
    .ss-billboard-layout .ss-feature-list li svg { width: 14px; height: 14px; }
    
    .ss-bg-red { background: #b02a2a !important; }
    .ss-bg-blue { background: #1f6baf !important; }
    .ss-bg-green { background: #2f5c42 !important; }
    .ss-text-red li svg { color: #b02a2a !important; }
    .ss-text-blue li svg { color: #1f6baf !important; }
    .ss-text-green li svg { color: #2f5c42 !important; }
    
    .ss-bubble-red { color: #b02a2a !important; border: 1px solid #b02a2a; }
    .ss-bubble-blue { color: #1f6baf !important; border: 1px solid #1f6baf; }
    .ss-bubble-green { color: #2f5c42 !important; border: 1px solid #2f5c42; }
    
    @media (max-width: 992px) {
      .ss-billboard-layout .ss-bottom-section { flex-direction: column; }
      .ss-billboard-layout .ss-app-mockup { width: 200px; }
    }
\n  </style>
  <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
</head>
<body>
  <svg class="svg-sprite" aria-hidden="true" focusable="false">
    <symbol id="icon-home" viewBox="0 0 24 24"><path d="M3 10.8 12 3l9 7.8" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><path d="M5.5 10.5V21h13V10.5" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><path d="M9.5 21v-6h5v6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></symbol>
    <symbol id="icon-search" viewBox="0 0 24 24"><circle cx="10.8" cy="10.8" r="6.8" fill="none" stroke="currentColor" stroke-width="2.5"/><path d="m16 16 5 5" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/></symbol>
    <symbol id="icon-shield" viewBox="0 0 24 24"><path d="M12 3 20 6v5.8c0 5-3.4 8.1-8 9.2-4.6-1.1-8-4.2-8-9.2V6l8-3Z" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linejoin="round"/><path d="m8.2 12.1 2.5 2.5 5.1-5.3" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></symbol>
    <symbol id="icon-key" viewBox="0 0 24 24"><path d="M9.5 14.5a5 5 0 1 1 3.7-8.4 5 5 0 0 1-3.7 8.4Z" fill="none" stroke="currentColor" stroke-width="2.4"/><path d="M13.2 10.8H22v3h-3v3h-3v-3h-2.8" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></symbol>
    <symbol id="icon-cap" viewBox="0 0 24 24"><path d="m3 8.5 9-4 9 4-9 4-9-4Z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/><path d="M6.5 11v4.3c2.9 2.3 8.1 2.3 11 0V11" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></symbol>
    <symbol id="icon-truck" viewBox="0 0 24 24"><path d="M3 6h11v10H3V6Z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/><path d="M14 9h4l3 3v4h-7V9Z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/><circle cx="7" cy="18" r="2" fill="none" stroke="currentColor" stroke-width="2.2"/><circle cx="18" cy="18" r="2" fill="none" stroke="currentColor" stroke-width="2.2"/></symbol>
    <symbol id="icon-phone" viewBox="0 0 24 24"><rect x="7" y="2.8" width="10" height="18.4" rx="2.4" fill="none" stroke="currentColor" stroke-width="2.3"/><path d="M10.5 18h3" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round"/></symbol>
    <symbol id="icon-bell" viewBox="0 0 24 24"><path d="M6 10a6 6 0 0 1 12 0v4.8l2 2.7H4l2-2.7V10Z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/><path d="M9.5 20a2.8 2.8 0 0 0 5 0" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></symbol>
    <symbol id="icon-user" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M4.8 20c1.2-4 4-6 7.2-6s6 2 7.2 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></symbol>
    <symbol id="icon-check" viewBox="0 0 24 24"><path d="m5 12.6 4.4 4.4L19 7" fill="none" stroke="currentColor" stroke-width="2.7" stroke-linecap="round" stroke-linejoin="round"/></symbol>
  </svg>

  <div class="landing-bulletin is-visible" id="landing-bulletin" role="region" aria-label="গুরুত্বপূর্ণ ঘোষণা">
    <span class="landing-bulletin-label">ঘোষণা</span>
    <div class="landing-bulletin-window">
      <div class="landing-bulletin-track" id="landing-bulletin-track">
        <span>আমরা এই কোম্পানির ১% শেয়ার হতদরিদ্রদের মাঝে দেব।</span>
      </div>
    </div>
  </div>

  <header class="site-header">
    <nav class="navbar" aria-label="প্রধান মেনু">
      <a class="brand" href="#home" aria-label="আমার ঠিকানা হোম">
        <span class="brand-text">
          <img src="amar_thikanaa_logo.png" alt="Amar Thikanaa">
          <small>Smart Marketplace ও Local Service—সব এক ঠিকানায়</small>
        </span>
      </a>

      <button class="nav-toggle" type="button" aria-label="মেনু খুলুন" aria-expanded="false">
        <span></span><span></span><span></span>
      </button>

      <div class="nav-links">
        <a href="#services" data-bn="সার্ভিস" data-en="Services">সার্ভিস</a>
        <a href="#grocery-products" data-bn="Smart Bazar" data-en="Smart Bazar">Smart Bazar</a>
        <a href="#team-network" data-bn="টিম ও এজেন্ট" data-en="Team & Agents">টিম ও এজেন্ট</a>
        <a href="/track-order" style="color: var(--primary); font-weight: 800;" data-bn="📦 ট্র্যাকিং" data-en="📦 Track Order">📦 ট্র্যাকিং</a>
      </div>

      <div class="top-actions">
        <button id="lang-toggle-btn" type="button" style="padding: 7px 14px; border-radius: 999px; border: 1px solid var(--border); background: #fff; font-weight: 800; cursor: pointer; color: var(--primary);">🌐 EN</button>
        <a class="top-login-btn" href="/Account/Login" data-bn="লগইন" data-en="Login">লগইন</a>
      </div>
    </nav>
  </header>

  <main id="home">
    <section class="hero-section">
      <div class="hero-wrap">
        <div class="hero-copy">
          <span class="eyebrow">✨ AmarThikanaa — আপনার প্রয়োজনের স্মার্ট ঠিকানা</span>
          <h1 id="typing-heading" class="typing-container" aria-label="খুঁজুন, কিনুন, বিক্রি করুন, সেবা নিন—সব এক ঠিকানায়, Amar Thikanaa."><span class="typing-text"></span><span class="typing-cursor">|</span></h1>
          <p>Amar Thikanaa হলো একটি Smart Marketplace ও Local Service Platform, যেখানে মানুষ নিরাপদে পণ্য কিনতে-বিক্রি করতে, স্থানীয় সেবা খুঁজতে এবং ব্যবসার সঙ্গে সরাসরি যুক্ত হতে পারে।</p>

          <div class="hero-actions">
            <a class="btn btn-primary" href="#grocery-products">Smart Bazar দেখুন <span aria-hidden="true">→</span></a>
            <a class="btn btn-light" href="#services">সব সার্ভিস দেখুন</a>
          </div>

          <div class="hero-proof" aria-label="প্ল্যাটফর্মের সুবিধা">
            <span>নিরাপদ কেনাবেচা</span>
            <span>স্থানীয় ব্যবসার সঙ্গে সরাসরি যোগাযোগ</span>
            <span>সহজ সার্ভিস রিকোয়েস্ট</span>
          </div>

          <form class="hero-search" action="#services">
            <input type="search" placeholder="পণ্য, দোকান বা প্রয়োজনীয় সেবা খুঁজুন..." aria-label="পণ্য, দোকান বা সেবা খুঁজুন">
            <button class="btn btn-green" type="submit">খুঁজুন</button>
          </form>

          <div class="popular-tags" aria-label="জনপ্রিয় সেবা">
            <a href="#services">ফ্ল্যাট ভাড়া</a>
            <a href="#services">বাসা খোঁজা</a>
            <a href="#services">শিক্ষক সার্ভিস</a>
            <a href="#grocery-products">Smart Bazar</a>
            <a href="#services">সেফটি ও SOS</a>
          </div>

          <div class="metric-row">
            <div><strong>Smart</strong><span>পণ্য ও স্থানীয় ব্যবসার ডিজিটাল বাজার</span></div>
            <div><strong>24/7</strong><span>অনলাইন রিকোয়েস্ট সুবিধা</span></div>
            <div><strong>Direct</strong><span>ক্রেতা, বিক্রেতা ও সেবাদাতার সংযোগ</span></div>
          </div>
        </div>

        <div class="hero-visual" id="dashboard">
          <div class="dashboard-card">
            <aside class="dash-sidebar">
              <div class="dash-logo">
                <img src="amar_thikanaa_icon.png" alt="">
                <div>
                  <strong>আমার ঠিকানা</strong>
                  <small>সব সার্ভিস এক জায়গায়</small>
                </div>
              </div>
              <a class="active" href="#"><svg><use href="#icon-home"></use></svg>হোম</a>
              <a href="#"><svg><use href="#icon-shield"></use></svg>নিরাপত্তা ও জরুরি সহায়তা</a>
              <a href="#"><svg><use href="#icon-key"></use></svg>নিরাপদ লেনদেন</a>
              <a href="#"><svg><use href="#icon-cap"></use></svg>শিক্ষক সেবা</a>
              <a href="#"><svg><use href="#icon-phone"></use></svg>ফোন যাচাই</a>
            </aside>

            <div class="dash-content">
              <div class="dash-topbar">
                <div class="search-box">
                  <input type="search" placeholder="সার্ভিস, বাসা বা প্রয়োজন লিখুন...">
                  <button type="button" aria-label="খুঁজুন"><svg><use href="#icon-search"></use></svg></button>
                </div>
                <a class="login-btn" href="/Account/Login">লগইন</a>
                <a class="login-btn" href="/Account/Register">ক্রেতা নিবন্ধন</a>
              </div>

              <div class="promo-banner">
                <div>
                  <h2>এক প্ল্যাটফর্মে<br>সহজ স্থানীয় সেবা</h2>
                  <p>প্রতিদিনের প্রয়োজনীয় সার্ভিস আরও সহজে</p>
                  <a href="#services">সার্ভিস দেখুন</a>
                </div>
                <div class="banner-phone">
                  <img src="amar_thikanaa_icon.png" alt="AmarThikanaa app নমুনা icon">
                </div>
              </div>

              <div class="dash-grid">
                <article><span>1</span><i class="green"><svg><use href="#icon-home"></use></svg></i><strong>ডিজিটাল বাজার</strong><small>পণ্য ও সেবার প্রচার</small></article>
                <article><span>2</span><i class="red"><svg><use href="#icon-shield"></use></svg></i><strong>নিরাপত্তা ও জরুরি সহায়তা</strong><small>জরুরি সহায়তা</small></article>
                <article><span>3</span><i class="blue"><svg><use href="#icon-key"></use></svg></i><strong>নিরাপদ লেনদেন</strong><small>নিরাপদে কেনাবেচা</small></article>
                <article><span>4</span><i class="violet"><svg><use href="#icon-cap"></use></svg></i><strong>শিক্ষক সেবা</strong><small>শিক্ষক খুঁজুন</small></article>
                <article><span>5</span><i class="orange"><svg><use href="#icon-home"></use></svg></i><strong>ফ্ল্যাট কেনাবেচা</strong><small>বাসা ও সম্পত্তির সেবা</small></article>
                <article><span>6</span><i class="teal"><svg><use href="#icon-phone"></use></svg></i><strong>ফোন যাচাই</strong><small>কেনার আগে যাচাই</small></article>
              </div>
            </div>
          </div>

          <div class="floating-card">
            <strong>সহজ অনুরোধ প্রক্রিয়া</strong>
            <span>প্রয়োজন জানান, দল অনুরোধ দেখবে, তারপর দ্রুত যোগাযোগ করবে।</span>
          </div>
        </div>
      </div>
    </section>

    <section class="network-stats-section" id="network-stats">
      <div class="container">
        <div class="network-stats-panel">
          <div class="network-stats-heading">
            <div>
              <span>আমাদের নেটওয়ার্ক</span>
              <h2>আমার ঠিকানার সঙ্গে যুক্ত মানুষ</h2>
            </div>
            <p>ক্রেতা, দোকানদার, ডেলিভারি কর্মী ও ফিল্ড কর্মীর হালনাগাদ সংখ্যা সরাসরি দেখানো হচ্ছে।</p>
          </div>
          <div class="network-stats-grid" aria-live="polite">
            <article class="network-stat-card customers">
              <i class="network-stat-icon">C</i>
              <strong class="network-count" data-key="customers">0</strong>
              <span>ক্রেতা</span>
            </article>
            <article class="network-stat-card shopkeepers">
              <i class="network-stat-icon">S</i>
              <strong class="network-count" data-key="shopkeepers">0</strong>
              <span>দোকানদার</span>
            </article>
            <article class="network-stat-card delivery">
              <i class="network-stat-icon">D</i>
              <strong class="network-count" data-key="deliveryMen">0</strong>
              <span>ডেলিভারি কর্মী</span>
            </article>
            <article class="network-stat-card field-force">
              <i class="network-stat-icon">F</i>
              <strong class="network-count" data-key="fieldForce">0</strong>
              <span>ফিল্ড কর্মী</span>
            </article>
          </div>
          <p class="network-stats-status">নেটওয়ার্কের তথ্য আসছে...</p>
        </div>
      </div>
    </section>

    <section class="section" id="district-leaderboard">
      <div class="container">
        <div class="leaderboard-panel">
          <div class="leaderboard-heading">
            <div>
              <span>জেলাভিত্তিক র্যাংকিং</span>
              <h2>প্রতিটি জেলার সেরা ৫০ ক্রেতা ও দোকানদার</h2>
            </div>
            <select class="leaderboard-district-select" id="leaderboardDistrict" aria-label="জেলা নির্বাচন করুন">
              <option value="">জেলা লোড হচ্ছে...</option>
            </select>
          </div>
          <div class="leaderboard-grid">
            <div class="leaderboard-col">
              <h3>টপ ক্রেতা (মোট কেনাকাটা অনুযায়ী)</h3>
              <ul class="leaderboard-list" id="topBuyersList">
                <li class="leaderboard-empty">লোড হচ্ছে...</li>
              </ul>
            </div>
            <div class="leaderboard-col">
              <h3>টপ দোকানদার (মোট বিক্রয় অনুযায়ী)</h3>
              <ul class="leaderboard-list" id="topShopkeepersList">
                <li class="leaderboard-empty">লোড হচ্ছে...</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="team-network-section" id="team-network">
      <div class="container">
        <div class="team-panel">
          <div class="team-header">
            <div>
              <span class="badge">👥 আমাদের মাঠপর্যায়ের প্রতিনিধি</span>
              <h2 data-bn="বিশ্বস্ত লোকাল এজেন্ট ও ফিল্ড টিম" data-en="Trusted Local Agents & Field Force">বিশ্বস্ত লোকাল এজেন্ট ও ফিল্ড টিম</h2>
              <p data-bn="আপনার এলাকায় সরাসরি সেবা, শপ অনবোর্ডিং বা জরুরি সহায়তার জন্য আমাদের সার্টিফাইড এজেন্ট ও ফিল্ড অফিসারদের সাথে যোগাযোগ করুন।" data-en="Connect directly with our certified agents and field officers for onboarding, services, and local support.">আপনার এলাকায় সরাসরি সেবা, শপ অনবোর্ডিং বা জরুরি সহায়তার জন্য আমাদের সার্টিফাইড এজেন্ট ও ফিল্ড অফিসারদের সাথে যোগাযোগ করুন।</p>
            </div>
          </div>

          <div class="team-controls-bar">
            <div class="team-role-tabs">
              <button type="button" class="team-tab-btn active" data-role="all" data-bn="⭐ সকল প্রতিনিধি" data-en="⭐ All Members">⭐ সকল প্রতিনিধি</button>
              <button type="button" class="team-tab-btn" data-role="Agent" data-bn="👑 এরিয়া এজেন্ট" data-en="👑 Area Agents">👑 এরিয়া এজেন্ট</button>
              <button type="button" class="team-tab-btn" data-role="FieldOfficer" data-bn="🛡️ ফিল্ড অফিসার" data-en="🛡️ Field Officers">🛡️ ফিল্ড অফিসার</button>
            </div>

            <div class="team-filter-inputs">
              <input type="text" id="teamSearchInput" class="team-search-input" placeholder="🔍 নাম, ফোন বা এলাকা খুঁজুন..." aria-label="Search members">
              <select id="teamDistrictFilter" class="team-district-select" aria-label="জেলা অনুযায়ী ফিল্টার">
                <option value="">সকল জেলা (All Districts)</option>
              </select>
            </div>
          </div>

          <div class="team-grid" id="teamDirectoryGrid">
            <div style="grid-column: 1 / -1; padding: 40px; text-align: center; color: var(--muted);">
              তথ্য লোড হচ্ছে...
            </div>
          </div>

          <div class="team-join-cta">
            <div class="team-join-cta-text">
              <h4 data-bn="আপনি কি আপনার এলাকার এজেন্ট বা ফিল্ড পার্টনার হতে চান?" data-en="Want to become an Area Agent or Field Partner?">আপনি কি আপনার এলাকার এজেন্ট বা ফিল্ড পার্টনার হতে চান?</h4>
              <p data-bn="আমার ঠিকানা পরিবারের অংশ হয়ে নিজের ক্যারিয়ার ও উপার্জনের নতুন দিগন্ত উন্মোচন করুন।" data-en="Join the Amar Thikanaa network and unlock new career and earning opportunities in your locality.">আমার ঠিকানা পরিবারের অংশ হয়ে নিজের ক্যারিয়ার ও উপার্জনের নতুন দিগন্ত উন্মোচন করুন।</p>
            </div>
            <a href="#contact" class="team-join-cta-btn" data-bn="আবেদন করুন / যোগাযোগ" data-en="Apply Now / Contact">আবেদন করুন / যোগাযোগ</a>
          </div>
        </div>
      </div>
    </section>

    <section class="section service-section" id="services">
      <div class="container">
        <div class="section-heading">
          <span>আমাদের Service</span>
          <h2>প্রয়োজনীয় সার্ভিসগুলো</h2>
          <p>আপনি কী খুঁজছেন—বাসা, শিক্ষক, পিকআপ, সেফটি বা নিরাপদ ডিল—প্রতিটি সার্ভিস এখানে সহজভাবে ব্যাখ্যা করা আছে, যাতে সিদ্ধান্ত নিতে সময় নষ্ট না হয়।</p>
        </div>

        <div class="smart-solutions-banner">
          <div class="ss-banner-header">
            <div class="ss-logo-block">
              <div class="ss-logo-icon">
                <svg viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                  <circle cx="12" cy="7" r="2" fill="#1a7138"></circle>
                </svg>
              </div>
              <div class="ss-logo-text">আমার<br>ঠিকানা</div>
            </div>
            <div>
              <h3>বাসা খোঁজা, ভাড়া দেওয়া আর লেনদেন সমস্যা?<br><span>সমাধান একটাই – আমার ঠিকানা অ্যাপ</span></h3>
            </div>
          </div>
          
          <div class="ss-banner-body">
            <!-- Column 1: Search -->
            <div class="ss-col ss-col-1">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-red">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                  বাসা খোঁজা
                </div>
                <img src="https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80" alt="Thinking Man" class="person">
                <div class="ss-bubble ss-bubble-red">ভালো লোকেশন, সাশ্রয়ী ভাড়া, নির্ভরযোগ্য বাসা কোথায় পাবো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-red">
                    <span>&larr; বাসা খোঁজা</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#b71c1c"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মিরপুর <br> ২ রুম, ২ বাথ <br> ৳ ১২,০০০ / মাস</li>
                      <li><svg viewBox="0 0 24 24" fill="#b71c1c"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ধানমন্ডি <br> ৩ রুম, ২ বাথ <br> ৳ ২৫,০০০ / মাস</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-red">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে খুঁজে নিন আপনার পছন্দের বাসা</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> লোকেশন, বাজেট ও সুবিধা দিয়ে ফিল্টার</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ছবি, বিবরণ ও মালিকের তথ্য দেখুন</li>
                </ul>
              </div>
            </div>
            
            <!-- Column 2: Rent -->
            <div class="ss-col ss-col-2">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-blue">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                  ভাড়া দেওয়া
                </div>
                <img src="https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80" alt="Happy Landlord" class="person">
                <div class="ss-bubble ss-bubble-blue">বিশ্বস্ত ভাড়াটে পাবো তো? ভাড়া আদায় হবে তো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-blue">
                    <span>&larr; ভাড়া দেওয়া</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মাই প্রপার্টি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ভাড়াটে খুঁজুন</li>
                      <li><svg viewBox="0 0 24 24" fill="#1565c0"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-blue">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে প্রপার্টি লিস্ট করুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বিশ্বস্ত ভাড়াটে খুঁজুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চুক্তি ও ভাড়া ব্যবস্থাপনা করুন</li>
                </ul>
              </div>
            </div>
            
            <!-- Column 3: Security -->
            <div class="ss-col ss-col-3">
              <div class="ss-image-container">
                <div class="ss-tab ss-tab-green">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                  লেনদেন সমস্যা
                </div>
                <img src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80" alt="Worried Woman" class="person">
                <div class="ss-bubble ss-bubble-green">অগ্রিম টাকা, চুক্তি, ভাড়া নিয়ে ঝামেলা... কী করবো?</div>
              </div>
              <div class="ss-bottom-section">
                <div class="ss-app-mockup">
                  <div class="ss-app-mockup-header ss-bg-green">
                    <span>&larr; লেনদেন সুরক্ষা</span>
                  </div>
                  <div class="ss-mockup-body">
                    <ul class="ss-inner-list">
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ডিজিটাল চুক্তি</li>
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> নিরাপদ পেমেন্ট</li>
                      <li><svg viewBox="0 0 24 24" fill="#1b5e20"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পেমেন্ট হিস্ট্রি</li>
                    </ul>
                  </div>
                </div>
                <ul class="ss-feature-list ss-text-green">
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ডিজিটাল চুক্তি ও নিরাপদ লেনদেন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> ভাড়া ও পেমেন্ট ট্র্যাক করুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সমস্যা হলে সাপোর্ট টিম পাশে আছে</li>
                </ul>
              </div>
            </div>
          </div>
          
          <div class="ss-banner-footer">
            <div class="ss-footer-left">
              <div class="ss-footer-left-icon">
                <svg viewBox="0 0 24 24" fill="#1a7138" stroke="#1a7138" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
              </div>
              <div>
                <h4>আমার ঠিকানা</h4>
                <p>সহজে বাসা খুঁজুন, ভাড়া দিন, নিরাপদ লেনদেন করুন</p>
              </div>
            </div>
            <div class="ss-footer-right">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" title="Google Play">
              <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" title="App Store">
            </div>
          </div>
        </div>

        <div class="sos-showcase-section">
          <!-- Phone 1 -->
          <div class="sos-phone-mockup">
            <div class="sos-phone-notch"></div>
            <div class="sos-phone-content">
              <div class="sos-app-header">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
                <div style="display:flex; align-items:center; gap:8px;">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="#10b981"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
                  <span style="font-weight:700; font-size: 14px;">আমার ঠিকানা<br><small style="font-size:10px; font-weight:400; color:#9ca3af;">নিরাপদ থাকুন, নিরাপদ রাখুন</small></span>
                </div>
                <div style="position:relative;">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>
                  <span style="position:absolute; top:-5px; right:-5px; background:#ef4444; color:#fff; font-size:8px; width:14px; height:14px; border-radius:50%; display:flex; align-items:center; justify-content:center;">3</span>
                </div>
              </div>
              
              <div class="sos-user-profile" style="margin-bottom:20px;">
                <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80" alt="User">
                Hello, সুমনা আক্তার
              </div>

              <div class="sos-hero-card">
                <div>
                  <h2>Emergency<br>Safety</h2>
                  <p>আপনার নিরাপত্তা,<br>আমাদের অগ্রাধিকার</p>
                </div>
                <div class="sos-hero-icon">
                  <svg viewBox="0 0 24 24" fill="rgba(255,255,255,0.9)"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 6c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 10.9c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/></svg>
                </div>
              </div>

              <div class="sos-grid">
                <div class="sos-card red">
                  <div class="sos-card-icon">SOS</div>
                  <h4>SOS Alert</h4>
                  <p>জরুরি সাহায্য চান</p>
                </div>
                <div class="sos-card blue">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg></div>
                  <h4>Live Location</h4>
                  <p>লাইভ লোকেশন শেয়ার</p>
                </div>
                <div class="sos-card green">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg></div>
                  <h4>Emergency Contacts</h4>
                  <p>জরুরি যোগাযোগ</p>
                </div>
                <div class="sos-card purple">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"></rect><path d="M12 11V3"></path><path d="M8 11V7h8v4"></path></svg></div>
                  <h4>Emergency Services</h4>
                  <p>পুলিশ, অ্যাম্বুলেন্স, ফায়ার সার্ভিস</p>
                </div>
                <div class="sos-card orange">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"></path><path d="M19 10v2a7 7 0 0 1-14 0v-2"></path><line x1="12" y1="19" x2="12" y2="22"></line></svg></div>
                  <h4>Audio Recording</h4>
                  <p>অডিও রেকর্ডিং</p>
                </div>
                <div class="sos-card teal">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="23 7 16 12 23 17 23 7"></polygon><rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect></svg></div>
                  <h4>Video Recording</h4>
                  <p>ভিডিও রেকর্ডিং</p>
                </div>
                <div class="sos-card pink">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg></div>
                  <h4>Quick Evidence</h4>
                  <p>ছবি/ভিডিও সংরক্ষণ</p>
                </div>
                <div class="sos-card darkblue">
                  <div class="sos-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg></div>
                  <h4>Safety Tips</h4>
                  <p>নিরাপত্তা টিপস</p>
                </div>
              </div>
            </div>
            <div class="sos-bottom-nav">
              <div class="sos-nav-item active"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path></svg>হোম</div>
              <div class="sos-nav-item"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path></svg>ঠিকানা</div>
              <div class="sos-nav-center"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg></div>
              <div class="sos-nav-item"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path></svg>সেবা</div>
              <div class="sos-nav-item"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>প্রোফাইল</div>
            </div>
          </div>

          <!-- Phone 2 -->
          <div class="sos-phone-mockup">
            <div class="sos-phone-notch"></div>
            <div class="sos-phone-content">
              <div class="sos-alert-header">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
                <h3>SOS Alert</h3>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
              </div>

              <div class="sos-big-button-wrapper">
                <div class="sos-big-button">SOS</div>
                <p>৩ সেকেন্ড চাপুন<br>জরুরি সাহায্য পাঠাতে</p>
              </div>

              <div class="sos-location-card">
                <div class="sos-card-head">
                  <span>লাইভ লোকেশন শেয়ার</span>
                  <span class="sos-live-tag"><svg width="8" height="8" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="12"></circle></svg> Live</span>
                </div>
                <div class="sos-map-box">
                  <div class="sos-map-pin"></div>
                </div>
                <div style="display:flex; justify-content:space-between; align-items:center;">
                  <p>Road-15, Dhanmondi, Dhaka-1209</p>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" stroke-width="2"><polygon points="3 11 22 2 13 21 11 13 3 11"></polygon></svg>
                </div>
              </div>

              <div class="sos-contacts-section">
                <div style="display:flex; justify-content:space-between; align-items:center;">
                  <h4>জরুরি যোগাযোগ (৩)</h4>
                  <span style="font-size:11px; color:#3b82f6; cursor:pointer;">সব দেখুন</span>
                </div>
                
                <div class="sos-contact-item">
                  <div class="sos-contact-info">
                    <img src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=64&q=80" alt="Ma">
                    <div>
                      <h5>মা</h5>
                      <p>+880 1712-345678</p>
                    </div>
                  </div>
                  <button class="sos-send-btn">পাঠান <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg></button>
                </div>
                
                <div class="sos-contact-item">
                  <div class="sos-contact-info">
                    <img src="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=64&q=80" alt="Abbu">
                    <div>
                      <h5>আব্বু</h5>
                      <p>+880 1621-123456</p>
                    </div>
                  </div>
                  <button class="sos-send-btn">পাঠান <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg></button>
                </div>
                
                <div class="sos-contact-item">
                  <div class="sos-contact-info">
                    <img src="https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=64&q=80" alt="Bon">
                    <div>
                      <h5>বোন</h5>
                      <p>+880 1912-654321</p>
                    </div>
                  </div>
                  <button class="sos-send-btn">পাঠান <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg></button>
                </div>
              </div>

              <button class="sos-action-btn">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                সকলকে সতর্কবার্তা পাঠান
              </button>
            </div>
          </div>
        </div>

        <div class="grocery-section">
          <div class="grocery-header">
            <div class="grocery-header-left">
              <img src="amar_thikanaa_icon.png" alt="Amar Thikana" class="logo">
              <div class="grocery-header-text">
                <h2>সরাসরি মুদি দোকান ও গ্রাহক</h2>
                <h3>সহজ অর্ডার, বিশ্বস্ত লেনদেন, সবার জন্য লাভ!</h3>
                <p>আমার ঠিকানা অ্যাপে এখন কাছের মুদি দোকান থেকে অর্ডার দিন সহজেই</p>
              </div>
            </div>
            <div class="grocery-header-right">
              <img src="https://images.unsplash.com/photo-1580828369062-f67d4f40f065?auto=format&fit=crop&w=300&q=80" alt="Woman on phone">
            </div>
          </div>

          <div class="grocery-steps">
            <!-- Step 1 -->
            <div class="grocery-step">
              <div class="grocery-step-header"><span class="step-num">1</span> কাছের মুদি দোকান খুঁজুন</div>
              <div class="grocery-step-img-box">
                <img src="https://images.unsplash.com/photo-1522204523234-8729aa6e3d5f?auto=format&fit=crop&w=300&q=80" alt="Step 1">
                <div class="grocery-mini-phone" style="bottom:-30px; right:10px;">
                  <div style="background:#166534;color:#fff;padding:4px;border-radius:4px 4px 0 0;text-align:center;">&larr; কাছের দোকান</div>
                  <div style="padding:4px;">
                    <div style="display:flex;gap:4px;margin-bottom:4px;background:#f0f0f0;padding:2px;border-radius:4px;">
                      <div style="width:20px;height:20px;background:#ccc;"></div>
                      <div><b>মা স্টোর</b><br>0.2 কিমি দূরে</div>
                    </div>
                    <div style="display:flex;gap:4px;margin-bottom:4px;background:#f0f0f0;padding:2px;border-radius:4px;">
                      <div style="width:20px;height:20px;background:#ccc;"></div>
                      <div><b>বনি স্টোর</b><br>0.3 কিমি দূরে</div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="grocery-step-text">আপনার অবস্থানের আশেপাশের বিশ্বস্ত মুদি দোকান দেখুন ও সিলেক্ট করুন</div>
            </div>
            <div class="grocery-step-arrow"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 16 16 12 12 8"></polyline><line x1="8" y1="12" x2="16" y2="12"></line></svg></div>

            <!-- Step 2 -->
            <div class="grocery-step">
              <div class="grocery-step-header"><span class="step-num">2</span> অর্ডার দিন সহজেই</div>
              <div class="grocery-step-img-box">
                <img src="https://images.unsplash.com/photo-1512428559087-560fa5ceab42?auto=format&fit=crop&w=300&q=80" alt="Step 2">
                <div class="grocery-mini-phone" style="bottom:-30px; right:10px;">
                  <div style="background:#166534;color:#fff;padding:4px;border-radius:4px 4px 0 0;text-align:center;">&larr; অর্ডার কনফার্ম</div>
                  <div style="padding:4px;">
                    <div style="display:flex;justify-content:space-between;border-bottom:1px solid #ddd;padding:2px 0;"><span>চাল ১ কেজি</span><span>৳৬০</span></div>
                    <div style="display:flex;justify-content:space-between;border-bottom:1px solid #ddd;padding:2px 0;"><span>ডাল ১ কেজি</span><span>৳১২০</span></div>
                    <div style="margin-top:10px;text-align:center;background:#166534;color:#fff;padding:4px;border-radius:4px;">অর্ডার দিন</div>
                  </div>
                </div>
              </div>
              <div class="grocery-step-text">প্রয়োজনীয় পণ্য সিলেক্ট করে অর্ডার কনফার্ম করুন</div>
            </div>
            <div class="grocery-step-arrow"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 16 16 12 12 8"></polyline><line x1="8" y1="12" x2="16" y2="12"></line></svg></div>

            <!-- Step 3 -->
            <div class="grocery-step">
              <div class="grocery-step-header"><span class="step-num">3</span> বিশ্বস্ত লেনদেন</div>
              <div class="grocery-step-img-box">
                <img src="https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80" alt="Step 3">
              </div>
              <div class="grocery-step-text">দোকান থেকে দ্রুত ডেলিভারি পান এবং নিরাপদ পেমেন্ট করুন</div>
            </div>
            <div class="grocery-step-arrow"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 16 16 12 12 8"></polyline><line x1="8" y1="12" x2="16" y2="12"></line></svg></div>

            <!-- Step 4 -->
            <div class="grocery-step">
              <div class="grocery-step-header"><span class="step-num">4</span> ক্যাশব্যাক পান</div>
              <div class="grocery-step-img-box">
                <img src="https://images.unsplash.com/photo-1601987177651-8edfe6c20009?auto=format&fit=crop&w=300&q=80" alt="Step 4">
                <div class="grocery-mini-phone" style="bottom:10px; right:10px; transform:rotate(5deg); height:auto; text-align:center; padding:10px 5px;">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="#166534"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
                  <div style="font-size:10px;font-weight:700;margin-top:5px;">অভিনন্দন!</div>
                  <div style="font-size:8px;">আপনি ক্যাশব্যাক পেয়েছেন</div>
                  <div style="font-size:24px;font-weight:900;color:#166534;margin-top:5px;">৳15</div>
                </div>
              </div>
              <div class="grocery-step-text">প্রতিটি অর্ডারে পান নিশ্চিত ক্যাশব্যাক</div>
            </div>
            <div class="grocery-step-arrow"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 16 16 12 12 8"></polyline><line x1="8" y1="12" x2="16" y2="12"></line></svg></div>

            <!-- Step 5 -->
            <div class="grocery-step">
              <div class="grocery-step-header"><span class="step-num">5</span> দোকানদার ও গ্রাহক দুজনেই অ্যাওয়ার্ড পান</div>
              <div class="grocery-step-img-box">
                <img src="https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=300&q=80" alt="Step 5">
              </div>
              <div class="grocery-step-text">মাসিক সেরা পারফরম্যান্সে দোকানদার ও গ্রাহক দুজনেই পান আকর্ষণীয় অ্যাওয়ার্ড</div>
            </div>
          </div>

          <div class="grocery-trust-banner">
            <svg viewBox="0 0 24 24"><path d="M11.8 17.3c-.6-.4-1.4-.4-2 0l-3.2 2.2c-.8.6-2 .1-2-1v-4.5c0-.8-.3-1.5-.9-2L1.5 10c-.8-.7-.5-2 .5-2.2l4.8-.8c.7-.1 1.4-.6 1.7-1.3l2-4.5c.3-1 .8-1.5 1.5-1.5s1.2.5 1.5 1.5l2 4.5c.3.7 1 1.2 1.7 1.3l4.8.8c1 .2 1.3 1.5.5 2.2l-2.2 2c-.6.5-.9 1.2-.9 2v4.5c0 1.1-1.2 1.6-2 1l-3.2-2.2z"></path></svg>
            বিশ্বাসের সম্পর্ক, সবার জন্য লাভ – আমার ঠিকানা
          </div>

          <div class="grocery-footer">
            <div class="grocery-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <div>
                <h5>নিরাপদ লেনদেন</h5>
                <p>100% নিরাপদ ও বিশ্বস্ত পেমেন্ট</p>
              </div>
            </div>
            <div class="grocery-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
              <div>
                <h5>দ্রুত ডেলিভারি</h5>
                <p>আপনার সময় বাঁচায়</p>
              </div>
            </div>
            <div class="grocery-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              <div>
                <h5>সবার জন্য লাভজনক</h5>
                <p>গ্রাহক ও দোকানদার – দুজনেই জিতবে</p>
              </div>
            </div>
            <div class="grocery-footer-download">
              <img src="amar_thikanaa_icon.png" alt="Logo" style="height:45px; margin-right:15px; background:#166534; padding:5px; border-radius:10px;">
              <div>
                <h4 style="margin:0; font-size:18px; font-weight:800;">আমার ঠিকানা</h4>
                <p style="margin:0; font-size:13px; color:#555; font-weight:600;">এক অ্যাপে, সব ঠিকানা</p>
              </div>
              <div style="margin-left: 20px;">
                <div style="font-weight:700; font-size:14px; margin-bottom:6px; color:#166534;">এখনই ডাউনলোড করুন</div>
                <div style="display:flex; gap:10px;">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Play" style="height:35px; cursor:pointer;">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" style="height:35px; cursor:pointer;">
                </div>
              </div>
            </div>
          </div>
          </div>
        </div>

        <div class="tutor-section">
          <div class="tutor-header">
            <div class="tutor-header-logo">
              <img src="amar_thikanaa_icon.png" alt="Amar Thikana">
            </div>
            <div class="tutor-header-center">
              <h2>শিক্ষক খুঁজছেন? বা পড়াতে চান?</h2>
              <p>আমার ঠিকানা অ্যাপে সহজেই খুঁজুন এবং সুযোগ দিন শিক্ষাকে এগিয়ে নিতে</p>
            </div>
            <div class="tutor-header-right">
              <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3L1 9l4 2.18v6L12 21l7-3.82v-6l2-1.09V17h2V9L12 3zm6.82 6L12 12.72 5.18 9 12 5.28 18.82 9zM17 15.99l-5 2.73-5-2.73v-3.72L12 15l5-2.73v3.72z"/></svg>
              <div>শিক্ষা হোক সহজ,<br>সবার জন্য</div>
            </div>
          </div>

          <div class="tutor-main">
            <!-- Left Side -->
            <div class="tutor-side">
              <div class="tutor-side-box">শিক্ষক খুঁজছেন?</div>
              <ul class="tutor-features">
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বিষয় অনুযায়ী সার্চ করুন</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> অভিজ্ঞতাসম্পন্ন শিক্ষক খুঁজুন</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> রেটিং ও রিভিউ দেখুন</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> সহজে যোগাযোগ করুন</li>
              </ul>
              <img class="tutor-img" src="https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=400&q=80" alt="Student searching tutor" style="margin-top:20px;">
            </div>

            <!-- Center Phone -->
            <div class="tutor-center-phone">
              <div class="tutor-phone-mockup">
                <div class="tutor-phone-notch"></div>
                <div class="tutor-phone-header">
                  <div style="font-weight:700;text-align:center;font-size:16px;">&larr; শিক্ষক খুঁজুন</div>
                  <div class="tutor-search-bar">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    বিষয়, স্থান বা কীওয়ার্ড লিখুন...
                  </div>
                  <div style="font-size:12px;color:#555;display:flex;align-items:center;gap:5px;">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>
                    আমার অবস্থান: ধানমন্ডি, ঢাকা
                  </div>
                </div>
                <div class="tutor-list">
                  <div class="tutor-card">
                    <img src="https://randomuser.me/api/portraits/men/32.jpg" alt="Tutor">
                    <div class="tutor-card-info" style="flex:1;">
                      <h4>রাকিবুল ইসলাম</h4>
                      <p>গণিত</p>
                      <p>অভিজ্ঞতা: ৫ বছর</p>
                      <div style="display:flex;justify-content:space-between;align-items:center;">
                        <span class="rate">৳ ৫০০ / ঘণ্টা</span>
                        <span style="font-size:11px;color:#ff9800;font-weight:700;">★ 4.8 (120)</span>
                      </div>
                    </div>
                  </div>
                  <div class="tutor-card">
                    <img src="https://randomuser.me/api/portraits/women/44.jpg" alt="Tutor">
                    <div class="tutor-card-info" style="flex:1;">
                      <h4>ফারহানা তাসনিম</h4>
                      <p>ইংরেজি</p>
                      <p>অভিজ্ঞতা: ৩ বছর</p>
                      <div style="display:flex;justify-content:space-between;align-items:center;">
                        <span class="rate">৳ ৪০০ / ঘণ্টা</span>
                        <span style="font-size:11px;color:#ff9800;font-weight:700;">★ 4.7 (98)</span>
                      </div>
                    </div>
                  </div>
                  <div class="tutor-card">
                    <img src="https://randomuser.me/api/portraits/men/67.jpg" alt="Tutor">
                    <div class="tutor-card-info" style="flex:1;">
                      <h4>সাজ্জাদ হোসেন</h4>
                      <p>ফিজিক্স</p>
                      <p>অভিজ্ঞতা: ৬ বছর</p>
                      <div style="display:flex;justify-content:space-between;align-items:center;">
                        <span class="rate">৳ ৬০০ / ঘণ্টা</span>
                        <span style="font-size:11px;color:#ff9800;font-weight:700;">★ 4.9 (150)</span>
                      </div>
                    </div>
                  </div>
                  <div class="tutor-card">
                    <img src="https://randomuser.me/api/portraits/women/68.jpg" alt="Tutor">
                    <div class="tutor-card-info" style="flex:1;">
                      <h4>নুসরাত জাহান</h4>
                      <p>রসায়ন</p>
                      <p>অভিজ্ঞতা: ৪ বছর</p>
                      <div style="display:flex;justify-content:space-between;align-items:center;">
                        <span class="rate">৳ ৪৫০ / ঘণ্টা</span>
                        <span style="font-size:11px;color:#ff9800;font-weight:700;">★ 4.6 (76)</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Right Side -->
            <div class="tutor-side right">
              <div class="tutor-side-box">পড়াতে চান?</div>
              <ul class="tutor-features">
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> নিজের প্রোফাইল তৈরি করুন</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বিষয় ও সময় সেট করুন</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> শিক্ষার্থী পান আপনার কাজেই</li>
                <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> আয় করুন নিজের সময়ে</li>
              </ul>
              <img class="tutor-img" src="https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=400&q=80" alt="Tutor preparing" style="margin-top:20px;">
            </div>
          </div>

          <div class="tutor-action-banners">
            <div class="tutor-action-banner">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line><path d="M11 8v6"></path><path d="M8 11h6"></path></svg>
              <div>
                <h4>সহজে শিক্ষক খুঁজুন</h4>
                <p>আপনার প্রয়োজন অনুযায়ী সেরা শিক্ষক নির্বাচন করুন</p>
              </div>
            </div>
            <div class="tutor-action-banner">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><polyline points="17 11 19 13 23 9"></polyline></svg>
              <div>
                <h4>শিক্ষক হিসেবে যুক্ত হোন</h4>
                <p>আপনার জ্ঞান ছড়িয়ে দিন, গড়ে তুলুন উজ্জ্বল ভবিষ্যৎ</p>
              </div>
            </div>
          </div>

          <div class="tutor-footer">
            <div class="tutor-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <div>
                <h5>বিশ্বস্ত ও নিরাপদ</h5>
                <p>ভেরিফাইড শিক্ষক ও শিক্ষার্থী</p>
              </div>
            </div>
            <div class="tutor-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
              <div>
                <h5>সহজ যোগাযোগ</h5>
                <p>অ্যাপেই চ্যাট ও কল</p>
              </div>
            </div>
            <div class="tutor-footer-feature">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
              <div>
                <h5>নিরাপদ পেমেন্ট</h5>
                <p>সহজ ও নিরাপদ লেনদেন</p>
              </div>
            </div>
            <div class="tutor-footer-download">
              <div style="font-weight:700; font-size:14px; margin-bottom:6px; color:#111;">এখনই ডাউনলোড করুন</div>
              <div style="display:flex; gap:10px;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Play" style="height:35px; cursor:pointer;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" style="height:35px; cursor:pointer;">
              </div>
            </div>
          </div>
        </div>

        <div class="verify-section">
          <div class="verify-header">
            <div class="verify-header-logo">
              <img src="amar_thikanaa_icon.png" alt="Amar Thikana">
              <div>এক অ্যাপে, সব ঠিকানা</div>
            </div>
            <div class="verify-header-center">
              <h2>মোবাইল ফোন ভেরিফাই সার্ভিস</h2>
              <p>আপনার ফোন নিরাপদ তো? যাচাই করুন আমাদের সাথে</p>
            </div>
            <div class="verify-header-right">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <div>নিরাপদ লেনদেন<br>নিশ্চিত সেবা</div>
            </div>
          </div>

          <div class="verify-main">
            <!-- Left Side -->
            <div class="verify-side left">
              <div class="verify-speech-bubble">
                ফোন কেনার আগে<br>একবার ভেরিফাই করে<br>নিন, নিরাপদ থাকুন!
              </div>
            </div>

            <!-- Center Phone -->
            <div class="verify-center-phone">
              <div class="verify-phone-mockup">
                <div class="verify-phone-notch"></div>
                <div class="verify-phone-header">
                  <span>&larr;</span> ফোন ভেরিফাই রিপোর্ট
                </div>
                <div class="verify-phone-body">
                  <div class="verify-phone-product">
                    <img src="https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?auto=format&fit=crop&w=150&q=80" alt="Phone">
                    <div class="verify-phone-product-info">
                      <h4>Samsung Galaxy S23 Ultra</h4>
                      <p>IMEI: 3517329257XXXXX<br>Brand: Samsung<br>Model: Galaxy S23 Ultra<br>Storage: 12/256 GB</p>
                    </div>
                  </div>
                  
                  <div class="verify-phone-checklist">
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চোরা / হারানো</div>
                      <span>কোনো রেকর্ড নেই</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মামলার তথ্য</div>
                      <span>কোনো মামলা নেই</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> কিস্তির ফোন</div>
                      <span>হ্যাঁ, কিস্তির ফোন</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মোট কিস্তি</div>
                      <span>১২ মাস</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পরিশোধ বিল</div>
                      <span>৬ মাস</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বাকি কিস্তি</div>
                      <span>৬ মাস (প্রতি মাসে ২৫০০ টাকা)</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> পরিশোধ অবস্থা</div>
                      <span>পরিশোধ চলছে</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বর্তমান কন্ডিশন</div>
                      <span>ভালো</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> অনারশিপ</div>
                      <span>আসল মালিক: রবিউল ইসলাম</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> অনারশিপ পরিবর্তন</div>
                      <span>সম্ভব</span>
                    </div>
                    <div class="verify-phone-checkitem">
                      <div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> বাই / সেল স্ট্যাটাস</div>
                      <span>বাজারে বিক্রয়যোগ্য</span>
                    </div>
                  </div>
                  
                  <div class="verify-phone-safe-banner">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
                    <div>সামগ্রিকভাবে এই ফোনটি নিরাপদ<br>আপনি চাইলে কিনতে পারেন</div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Right Side -->
            <div class="verify-side right">
              <div class="verify-features-box">
                <h3>কেন ফোন ভেরিফাই করবেন?</h3>
                <ul>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> চোরা ফোন থেকে নিরাপদ থাকুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> মামলার ঝামেলা থেকে বাঁচুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> কিস্তির বাকি আছে কি না জানুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> আসল মালিক কে জানুন</li>
                  <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg> নিরাপদ লেনদেনে নিশ্চিত থাকুন</li>
                </ul>
              </div>
            </div>
          </div>

          <div class="verify-grid">
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle><rect x="4" y="11" width="16" height="4" rx="2"></rect></svg>
              <div>
                <h5>চোরা / হারানো চেক</h5>
                <p>ফোন চুরি বা হারানো কিনা তাৎক্ষণিক যাচাই করুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <div>
                <h5>মামলার তথ্য</h5>
                <p>ফোনের বিরুদ্ধে কোনো মামলা আছে কিনা জানুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
              <div>
                <h5>কিস্তির তথ্য</h5>
                <p>কিস্তির ফোন কিনা ও কতটি কিস্তি বাকি আছে দেখুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path></svg>
              <div>
                <h5>পরিশোধ অবস্থা</h5>
                <p>কিস্তি পরিশোধ নিয়মিত হচ্ছে কিনা যাচাই করুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>
              <div>
                <h5>বর্তমান কন্ডিশন</h5>
                <p>ফোনের বর্তমান অবস্থা (নতুন/ব্যবহৃত) জানুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
              <div>
                <h5>অনারশিপ যাচাই</h5>
                <p>আসল মালিকের তথ্য যাচাই করুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"></polyline><polyline points="23 20 23 14 17 14"></polyline><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"></path></svg>
              <div>
                <h5>অনারশিপ পরিবর্তন</h5>
                <p>সহজেই অনারশিপ পরিবর্তন করুন</p>
              </div>
            </div>
            <div class="verify-grid-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
              <div>
                <h5>বাই / সেল স্ট্যাটাস</h5>
                <p>বাজারে বিক্রয়যোগ্য কিনা জানুন</p>
              </div>
            </div>
          </div>

          <div class="verify-footer">
            <div class="verify-process">
              <div class="verify-process-badge">আমাদের কাজের পদ্ধতি</div>
              <div class="verify-process-steps">
                <div class="verify-step-item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>
                  <div>ফোনের IMEI দিয়ে সাবমিট করুন</div>
                </div>
                <span class="verify-step-arrow">&rarr;</span>
                <div class="verify-step-item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path><path d="M8 21h8"></path><path d="M12 17v4"></path></svg>
                  <div>সিস্টেম থেকে তথ্য সংগ্রহ</div>
                </div>
                <span class="verify-step-arrow">&rarr;</span>
                <div class="verify-step-item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                  <div>বিস্তারিত রিপোর্ট প্রস্তুত</div>
                </div>
                <span class="verify-step-arrow">&rarr;</span>
                <div class="verify-step-item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                  <div>রিপোর্ট দেখে নিশ্চিত হয়ে কিনুন / বিক্রি করুন</div>
                </div>
              </div>
            </div>

            <div style="display:flex; align-items:center; gap:20px;">
              <div style="display:flex; align-items:center; gap:10px;">
                <img src="amar_thikanaa_icon.png" alt="Logo" style="height:45px; background:#166534; padding:5px; border-radius:10px;">
                <div>
                  <h4 style="margin:0; font-size:18px; font-weight:800; color:#1e3a8a;">আমার ঠিকানা</h4>
                  <p style="margin:0; font-size:13px; color:#555; font-weight:600;">এক অ্যাপে, সব ঠিকানা</p>
                </div>
              </div>
              <div>
                <div style="font-weight:700; font-size:14px; margin-bottom:6px; color:#111;">এখনই ডাউনলোড করুন</div>
                <div style="display:flex; gap:10px;">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Play" style="height:35px; cursor:pointer;">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" style="height:35px; cursor:pointer;">
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="secure-section">
          <div class="secure-header">
            <div class="secure-header-title">
              <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-2 16l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z"/></svg>
              <h2>সিকিউর ডিল <span>(Secure Deal)</span></h2>
            </div>
            <div class="secure-header-subtitle">নিরাপদ লেনদেন, প্রতারণামুক্ত অভিজ্ঞতা</div>
          </div>

          <div class="secure-main">
            <!-- Buyer -->
            <div class="secure-person">
              <img src="https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0?auto=format&fit=crop&w=300&q=80" alt="Buyer">
              <div class="secure-person-label">ক্রেতা</div>
            </div>

            <!-- Flow -->
            <div class="secure-flow">
              <!-- Step 1 -->
              <div class="secure-step">
                <div class="secure-step-number">1</div>
                <div class="secure-step-icon">
                  <svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
                </div>
                <p>পণ্য অর্ডার</p>
              </div>
              <div class="secure-arrow">&rarr;</div>
              
              <!-- Step 2 -->
              <div class="secure-step">
                <div class="secure-step-number">2</div>
                <div class="secure-step-icon">
                  <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-2 16l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z"/></svg>
                </div>
                <p>আমরা রাখি নিরাপদে<br><span>(Escrow)</span></p>
              </div>
              <div class="secure-arrow">&rarr;</div>

              <!-- Step 3 -->
              <div class="secure-step">
                <div class="secure-step-number">3</div>
                <div class="secure-step-icon">
                  <svg viewBox="0 0 24 24" fill="currentColor"><path d="M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18s-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18s.41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15z"/></svg>
                  <div class="secure-step-check"><svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg></div>
                </div>
                <p>পণ্য হাতে পেয়ে<br>সাবমিট করুন</p>
              </div>
              <div class="secure-arrow">&rarr;</div>

              <!-- Step 4 -->
              <div class="secure-step">
                <div class="secure-step-number">4</div>
                <div class="secure-step-icon">
                  <svg viewBox="0 0 24 24" fill="currentColor"><path d="M21 18v1c0 1.1-.9 2-2 2H5c-1.11 0-2-.9-2-2V5c0-1.1.89-2 2-2h14c1.1 0 2 .9 2 2v1h-9c-1.11 0-2 .9-2 2v8c0 1.1.89 2 2 2h9zm-9-2h10V8H12v8zm4-2.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>
                  <div class="secure-step-check"><svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg></div>
                </div>
                <p>টাকা পৌঁছে যাবে<br>বিক্রেতার কাছে</p>
              </div>
            </div>

            <!-- Seller -->
            <div class="secure-person">
              <img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80" alt="Seller">
              <div class="secure-person-label">বিক্রেতা</div>
            </div>
          </div>

          <div class="secure-banner">
            <div class="secure-banner-left">
              <div class="secure-banner-shield">
                <svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>
              </div>
              <div class="secure-banner-text">
                <h3>আপনার নিরাপত্তা আমাদের অঙ্গীকার</h3>
                <p>প্রতারণার ঝুঁকি কম, লেনদেনে থাকুন নিশ্চিন্ত</p>
              </div>
            </div>
            <div class="secure-banner-right">
              <p>লেনদেন শেষে দিন রেটিং</p>
              <div class="secure-stars">
                <svg viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                <svg viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                <svg viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                <svg viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                <svg viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
              </div>
            </div>
          </div>

          <div class="secure-footer">
            <div class="secure-footer-item">
              <div class="secure-footer-item-icon shield"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg></div>
              নিরাপদ লেনদেন
            </div>
            <div class="secure-footer-item">
              <div class="secure-footer-item-icon"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zM9 6c0-1.66 1.34-3 3-3s3 1.34 3 3v2H9V6zm9 14H6V10h12v10zm-6-3c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2z"/></svg></div>
              মধ্যস্থতাকারী (Escrow)
            </div>
            <div class="secure-footer-item">
              <div class="secure-footer-item-icon"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg></div>
              প্রতারণার ঝুঁকি কম
            </div>
            <div class="secure-footer-item">
              <div class="secure-footer-item-icon"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></div>
              রেটিং ও রিভিউ সুবিধা
            </div>
          </div>
        </div>

        <div class="service-grid">
          <article class="service-card" data-service="ফ্ল্যাট ভাড়া">
            <i class="blue"><svg><use href="#icon-home"></use></svg></i>
            <h3>ফ্ল্যাট ভাড়া</h3>
            <p>বাড়িওয়ালা ও ভাড়াটিয়ার জন্য লোকেশন, বাজেট, ছবি, সুবিধা ও যোগাযোগের তথ্যসহ সহজ ফ্ল্যাট ভাড়া সার্ভিস।</p>
            <ul class="service-list">
              <li>Area ও বাজেট অনুযায়ী রিকোয়েস্ট</li>
              <li>ছবি, সুবিধা ও যোগাযোগের তথ্য</li>
              <li>দ্রুত আগ্রহী কাস্টমার Collection</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>

          <article class="service-card" data-service="ফ্ল্যাট বিক্রি">
            <i class="green"><svg><use href="#icon-key"></use></svg></i>
            <h3>ফ্ল্যাট বিক্রি</h3>
            <p>ফ্ল্যাট মালিক, ডেভেলপার বা সেলারদের জন্য পরিষ্কার তথ্য, ছবি ও লোকেশনসহ প্রপার্টি প্রমোশন সুবিধা।</p>
            <ul class="service-list">
              <li>দাম, সাইজ ও লোকেশন স্পষ্টভাবে দেখানো</li>
              <li>আগ্রহী ক্রেতার রিকোয়েস্ট Collection</li>
              <li>বিশ্বাসযোগ্য ডিল প্রেজেন্টেশন</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>

          <article class="service-card" data-service="বাসা খোঁজা">
            <i class="violet"><svg><use href="#icon-search"></use></svg></i>
            <h3>বাসা খোঁজা</h3>
            <p>ভাড়াটিয়া বা ক্রেতা তাদের Area, বাজেট ও পছন্দ জানাবে; AmarThikanaa উপযুক্ত অপশন খুঁজতে সহায়তা করবে।</p>
            <ul class="service-list">
              <li>এরিয়া, বাজেট ও পরিবারের প্রয়োজন</li>
              <li>পছন্দ অনুযায়ী মিল খুঁজে দেওয়া</li>
              <li>সহজ রিকোয়েস্ট ফর্ম</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>

          <article class="service-card" data-service="শিক্ষক সার্ভিস">
            <i class="teal"><svg><use href="#icon-cap"></use></svg></i>
            <h3>শিক্ষক সার্ভিস</h3>
            <p>স্টুডেন্ট, অভিভাবক ও শিক্ষকদের জন্য সাবজেক্ট, ক্লাস, লোকেশন এবং অনলাইন/অফলাইন অনুযায়ী শিক্ষক খোঁজার সুবিধা।</p>
            <ul class="service-list">
              <li>সাবজেক্টভিত্তিক শিক্ষক প্রোফাইল</li>
              <li>অভিভাবকের রিকোয়েস্ট Collection</li>
              <li>অনলাইন ও অফলাইন টিউশন অপশন</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>

          <article class="service-card" data-service="পিকআপ সার্ভিস">
            <i class="orange"><svg><use href="#icon-truck"></use></svg></i>
            <h3>পিকআপ সার্ভিস</h3>
            <p>বাসা বদল, মালামাল বহন, ছোট ডেলিভারি বা লোকাল ট্রান্সপোর্ট সাপোর্টের জন্য সহজ বুকিং ব্যবস্থা।</p>
            <ul class="service-list">
              <li>পিকআপ ও ড্রপ লোকেশন</li>
              <li>গাড়ির ধরন নির্বাচন</li>
              <li>সার্ভিস প্রোভাইডারের সাথে সংযোগ</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>

          <article class="service-card" data-service="সেফটি ও SOS">
            <i class="red"><svg><use href="#icon-shield"></use></svg></i>
            <h3>সেফটি ও SOS</h3>
            <p>জরুরি অবস্থায় দ্রুত যোগাযোগ, বিশ্বস্ত কন্টাক্ট, লোকেশন সাপোর্ট এবং সেফটি তথ্য দেখানোর জন্য বিশেষ সাপোর্ট সেকশন।</p>
            <ul class="service-list">
              <li>জরুরি যোগাযোগ flow</li>
              <li>সেফটি অ্যালার্ট দেখানোর সুবিধা</li>
              <li>নিরাপদ সাপোর্ট মেসেজ</li>
            </ul>
            <a class="card-link" href="#contact">এই সার্ভিস চাই →</a>
          </article>
        </div>

        <div class="trust-strip" aria-label="Trust highlights">
          <div class="trust-item"><i class="feature-icon blue"><svg><use href="#icon-check"></use></svg></i><div><strong>সহজ রিকোয়েস্ট</strong><small>নাম, নম্বর ও প্রয়োজন দিলেই শুরু</small></div></div>
          <div class="trust-item"><i class="feature-icon green"><svg><use href="#icon-shield"></use></svg></i><div><strong>বিশ্বাসযোগ্য তথ্য</strong><small>সার্ভিসের তথ্য পরিষ্কারভাবে উপস্থাপন</small></div></div>
          <div class="trust-item"><i class="feature-icon orange"><svg><use href="#icon-bell"></use></svg></i><div><strong>দ্রুত পরবর্তী যোগাযোগ</strong><small>রিকোয়েস্ট পাওয়ার পর দ্রুত যোগাযোগ</small></div></div>
          <div class="trust-item"><i class="feature-icon violet"><svg><use href="#icon-user"></use></svg></i><div><strong>ব্যবহার সহজ</strong><small>মোবাইলেও সুন্দরভাবে ব্যবহারযোগ্য</small></div></div>
        </div>
      </div>
    </section>

    <section class="section grocery-section" id="grocery-products">
      <div class="container">
        <div class="section-heading">
          <span>SMART BAZAR</span>
          <h2>নিরাপদে পণ্য খুঁজুন, কিনুন ও বিক্রি করুন</h2>
          <p>স্থানীয় দোকান ও ব্যবসার সঙ্গে সরাসরি যুক্ত হয়ে চাল, ডাল, তেলসহ নিত্যপ্রয়োজনীয় পণ্য দেখুন। সহজে পণ্য খুঁজুন, দাম জানুন এবং অর্ডার রিকোয়েস্ট পাঠান।</p>
        </div>

        <div class="smart-bazar-trustbar">
          <div><strong>বিশ্বস্ত স্থানীয় দোকান</strong><span>আপনার এলাকার ব্যবসা ও পণ্য এক জায়গায়</span></div>
          <div><strong>সহজ পণ্য অনুসন্ধান</strong><span>ক্যাটাগরি অনুযায়ী দ্রুত প্রয়োজনীয় পণ্য খুঁজুন</span></div>
          <div><strong>সরাসরি অর্ডার সংযোগ</strong><span>দোকান নির্বাচন করে সহজে অর্ডার রিকোয়েস্ট দিন</span></div>
        </div>

        <div class="grocery-showcase">
          <article class="grocery-feature">
            <span>AMAR THIKANAA SMART BAZAR</span>
            <h3>আপনার এলাকার বাজার এখন হাতের মুঠোয়</h3>
            <p>স্থানীয় দোকানের পণ্য দেখুন, দাম জানুন এবং বিশ্বস্ত ব্যবসার সঙ্গে সরাসরি যুক্ত হয়ে প্রয়োজনীয় অর্ডার করুন।</p>
            <ul class="marketplace-benefits">
              <li>ক্যাটাগরি অনুযায়ী সাজানো পণ্য</li>
              <li>দাম ও পণ্যের তথ্য একসঙ্গে</li>
              <li>ক্রেতা ও স্থানীয় দোকানের সরাসরি সংযোগ</li>
            </ul>
            <div class="marketplace-actions">
              <a class="btn btn-primary" href="/Account/Register">ক্রেতা হিসেবে শুরু করুন</a>
              <a class="btn btn-light" href="/Account/Login">লগইন করুন</a>
            </div>
          </article>

          <div class="grocery-grid">
            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=900&q=80" alt="সাদা চালের বস্তা ও বাটি">
              <div class="product-info">
                <strong>মিনিকেট চাল</strong>
                <span>পরিবারের প্রতিদিনের রান্নার জন্য মানসম্মত ও পরিচ্ছন্ন প্যাকেট চাল।</span>
                <div class="product-meta"><b>চাল</b><b>৫ কেজি / ২৫ কেজি</b></div>
              </div>
            </article>

            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1515543904379-3d757afe72e4?auto=format&fit=crop&w=900&q=80" alt="বিভিন্ন ডাল ও শস্য">
              <div class="product-info">
                <strong>মসুর ডাল</strong>
                <span>পুষ্টিকর ও ভালো মানের মসুর ডাল—দৈনন্দিন বাজারের প্রয়োজনীয় পণ্য।</span>
                <div class="product-meta"><b>ডাল</b><b>১ কেজি</b></div>
              </div>
            </article>

            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=900&q=80" alt="রান্নার তেলের বোতল">
              <div class="product-info">
                <strong>সয়াবিন তেল</strong>
                <span>পরিবারের রান্নার জন্য জনপ্রিয় সয়াবিন তেল, প্রয়োজন অনুযায়ী বিভিন্ন সাইজে।</span>
                <div class="product-meta"><b>তেল</b><b>১ লিটার / ৫ লিটার</b></div>
              </div>
            </article>

            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80" alt="আটা ও রুটির উপকরণ">
              <div class="product-info">
                <strong>আটা ও ময়দা</strong>
                <span>রুটি, পরোটা ও বেকারির জন্য প্রয়োজনীয় আটা ও ময়দা সহজে খুঁজুন।</span>
                <div class="product-meta"><b>আটা</b><b>২ কেজি / ৫ কেজি</b></div>
              </div>
            </article>

            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=900&q=80" alt="বিভিন্ন রঙের মসলা">
              <div class="product-info">
                <strong>হলুদ, মরিচ ও মসলা</strong>
                <span>প্রতিদিনের রান্নার জন্য নির্বাচিত হলুদ, মরিচ ও প্রয়োজনীয় মসলা।</span>
                <div class="product-meta"><b>মসলা</b><b>১০০ গ্রাম / ২০০ গ্রাম</b></div>
              </div>
            </article>

            <article class="product-card">
              <img src="https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?auto=format&fit=crop&w=900&q=80" alt="চা পাতা ও চায়ের কাপ">
              <div class="product-info">
                <strong>চা পাতা</strong>
                <span>সকালের নাশতা ও অতিথি আপ্যায়নের জন্য পছন্দের মানসম্মত চা পাতা।</span>
                <div class="product-meta"><b>চা</b><b>২০০ গ্রাম / ৫০০ গ্রাম</b></div>
              </div>
            </article>
          </div>
        </div>
      </div>
    </section>

    <section class="section" id="how-it-works">
      <div class="container">
        <div class="split-section">
          <div>
            <span class="eyebrow">সহজ প্রক্রিয়া</span>
            <h2>কীভাবে AmarThikanaa কাজ করে?</h2>
            <p>AmarThikanaa ব্যবহার করা খুব সহজ। আপনি প্রয়োজনীয় সার্ভিস বেছে রিকোয়েস্ট পাঠাবেন, তারপর সংশ্লিষ্ট টিম বা সার্ভিস প্রোভাইডার দ্রুত যোগাযোগ করবে।</p>

            <div class="step-list">
              <div class="step-item">
                <div class="step-number">1</div>
                <div><strong>সার্ভিস নির্বাচন</strong><span>আপনি প্রয়োজন অনুযায়ী ফ্ল্যাট, শিক্ষক, পিকআপ, SOS বা অন্য সার্ভিস নির্বাচন করবেন।</span></div>
              </div>
              <div class="step-item">
                <div class="step-number">2</div>
                <div><strong>রিকোয়েস্ট পাঠানো</strong><span>নাম, মোবাইল নম্বর, লোকেশন ও প্রয়োজনীয় তথ্য দিয়ে রিকোয়েস্ট সাবমিট করবেন।</span></div>
              </div>
              <div class="step-item">
                <div class="step-number">3</div>
                <div><strong>যোগাযোগ ও সেবা নিশ্চিত করা</strong><span>দায়িত্বপ্রাপ্ত দল দ্রুত যোগাযোগ করে উপযুক্ত সমাধান দেবে।</span></div>
              </div>
            </div>
          </div>

          <div class="process-panel">
            <div class="process-card">
              <small>ব্যবহারকারীর জন্য</small>
              <h3>এক জায়গায় সব সার্ভিস</h3>
              <p>একাধিক ওয়েবসাইট বা ফেসবুক গ্রুপ ঘুরতে হবে না। প্রয়োজনীয় সার্ভিস সহজেই এক জায়গা থেকে খুঁজে নিতে পারবেন।</p>
            </div>
            <div class="process-card">
              <small>ব্যবসার জন্য</small>
              <h3>রিকোয়েস্ট Collection সহজ হবে</h3>
              <p>কন্টাক্ট ফর্ম, সার্ভিস নির্বাচন ও লাইভ চ্যাট থাকার কারণে আগ্রহী কাস্টমারের তথ্য পরিষ্কারভাবে পাওয়া যাবে।</p>
            </div>
            <div class="process-card">
              <small>আস্থার জন্য</small>
              <h3>প্রফেশনাল প্রেজেন্টেশন</h3>
              <p>ক্লিন লেআউট, ড্যাশবোর্ড প্রিভিউ, সাধারণ প্রশ্ন এবং ট্রাস্ট পয়েন্ট থাকার কারণে প্ল্যাটফর্ম আরও বিশ্বাসযোগ্য দেখাবে।</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="section" id="audience">
      <div class="container">
        <div class="section-heading">
          <span>কারা ব্যবহার করবেন</span>
          <h2>কার জন্য AmarThikanaa সবচেয়ে উপকারী?</h2>
          <p>বাড়িওয়ালা, ভাড়াটিয়া, শিক্ষক, অভিভাবক, সার্ভিস প্রোভাইডার—সবাই তাদের প্রয়োজন অনুযায়ী এই প্ল্যাটফর্ম ব্যবহার করতে পারবেন।</p>
        </div>

        <div class="audience-grid">
          <div class="audience-card"><i class="blue"><svg><use href="#icon-home"></use></svg></i><strong>বাড়িওয়ালা</strong><span>ফ্ল্যাট ভাড়া বা বিক্রির জন্য আগ্রহী ক্রেতা পাবেন।</span></div>
          <div class="audience-card"><i class="green"><svg><use href="#icon-search"></use></svg></i><strong>ভাড়াটিয়া</strong><span>এরিয়া, বাজেট ও সুবিধা অনুযায়ী বাসা খুঁজতে পারবেন।</span></div>
          <div class="audience-card"><i class="violet"><svg><use href="#icon-cap"></use></svg></i><strong>শিক্ষক</strong><span>টিউশন প্রোফাইল তৈরি করে শিক্ষার্থী/অভিভাবকের রিকোয়েস্ট পাবেন।</span></div>
          <div class="audience-card"><i class="orange"><svg><use href="#icon-truck"></use></svg></i><strong>সার্ভিস প্রোভাইডার</strong><span>পিকআপ, রিপেয়ার বা লোকাল সার্ভিস সুন্দরভাবে প্রমোট করতে পারবেন।</span></div>
          <div class="audience-card"><i class="red"><svg><use href="#icon-shield"></use></svg></i><strong>সাধারণ ইউজার</strong><span>নিরাপদ ডিল, ফোন যাচাই ও SOS সাপোর্ট ব্যবহার করতে পারবেন।</span></div>
        </div>
      </div>
    </section>

    <section class="section" id="highlights">
      <div class="container">
        <div class="section-heading">
          <span>বিশেষ সুবিধা</span>
          <h2>আরও সহজ রিকোয়েস্ট, আরও সুন্দর সার্ভিস প্রেজেন্টেশন</h2>
          <p>AmarThikanaa শুধু সুন্দর ডিজাইন নয়—এটি ব্যবহারকারীকে তথ্য দেয়, আস্থা তৈরি করে এবং দ্রুত যোগাযোগের সুযোগ করে দেয়।</p>
        </div>

        <div class="highlight-grid">
          <article class="highlight-card lead-card">
            <span>01</span>
            <h3>কাস্টমার রিকোয়েস্ট Collection</h3>
            <p>আগ্রহী কাস্টমার নাম, মোবাইল নম্বর, সার্ভিস ও প্রয়োজনীয় তথ্য দিয়ে রিকোয়েস্ট পাঠাবে। ফলে পরবর্তী যোগাযোগ অনেক সহজ হবে।</p>
          </article>
          <article class="highlight-card spotlight-card">
            <span>02</span>
            <h3>সার্ভিসগুলো সুন্দরভাবে উপস্থাপন</h3>
            <p>ফ্ল্যাট, শিক্ষক, পিকআপ, SOS ও নিরাপদ ডিল—সব সার্ভিস আলাদা কার্ড ও সহজ ব্যাখ্যাসহ সাজানো থাকবে।</p>
          </article>
          <article class="highlight-card trust-card">
            <span>03</span>
            <h3>বিশ্বাসযোগ্য প্রেজেন্টেশন</h3>
            <p>প্রফেশনাল লোগো এরিয়া, ড্যাশবোর্ড প্রিভিউ, কীভাবে কাজ করে সেকশন, সাধারণ প্রশ্ন ও লাইভ চ্যাট প্ল্যাটফর্মের আস্থা বাড়াবে।</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="faq">
      <div class="container">
        <div class="faq-wrap">
          <div class="faq-side">
            <span class="section-heading span" style="display:inline-flex;padding:7px 13px;border-radius:999px;background:#eff6ff;color:#2563eb;font-weight:900;font-size:14px;">সাধারণ প্রশ্ন</span>
            <h2>সাধারণ প্রশ্নের সহজ উত্তর</h2>
            <p>নতুন ব্যবহারকারীরা যেন দ্রুত সিদ্ধান্ত নিতে পারেন, তাই গুরুত্বপূর্ণ প্রশ্নের উত্তর সহজভাবে দেওয়া হলো।</p>
            <a class="btn btn-primary" href="#contact">আরও জানতে চাই</a>
          </div>

          <div class="faq-list">
            <div class="faq-item open">
              <button class="faq-question" type="button">AmarThikanaa কোন ধরনের সার্ভিস দেয়? <span>−</span></button>
              <div class="faq-answer">ফ্ল্যাট ভাড়া বা বিক্রি, বাসা খোঁজা, শিক্ষক, পিকআপ, জরুরি সহায়তা, নিরাপদ লেনদেন ও ফোন যাচাইয়ের সেবা এক জায়গায় দেওয়ার জন্য আমার ঠিকানা তৈরি।</div>
            </div>
            <div class="faq-item">
              <button class="faq-question" type="button">আমি কীভাবে সার্ভিস রিকোয়েস্ট করব? <span>+</span></button>
              <div class="faq-answer">নিচের ফর্মে আপনার নাম, মোবাইল নম্বর, সার্ভিসের ধরন এবং প্রয়োজনীয় Message লিখে সাবমিট করুন। এরপর টিম বা সার্ভিস প্রোভাইডার আপনার সাথে যোগাযোগ করবে।</div>
            </div>
            <div class="faq-item">
              <button class="faq-question" type="button">এটা কি মোবাইলে সুন্দরভাবে ব্যবহার করা যাবে? <span>+</span></button>
              <div class="faq-answer">হ্যাঁ, এই পেজ মোবাইল, ট্যাবলেট ও ডেস্কটপ—সব স্ক্রিনে সুন্দরভাবে ব্যবহারযোগ্য।</div>
            </div>
            <div class="faq-item">
              <button class="faq-question" type="button">সার্ভিস প্রোভাইডার হিসেবে আমি কীভাবে উপকার পাব? <span>+</span></button>
              <div class="faq-answer">আপনার সার্ভিস সুন্দরভাবে উপস্থাপন হবে, আগ্রহী কাস্টমার ফর্ম পূরণ করবে, এবং আপনি সেই রিকোয়েস্ট ধরে সহজে পরবর্তী যোগাযোগ করতে পারবেন।</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="section" id="contact">
      <div class="container">
        <div class="contact-section">
          <div class="contact-copy">
            <span>যোগাযোগ</span>
            <h2>আপনার প্রয়োজনীয় সার্ভিসের জন্য এখনই রিকোয়েস্ট করুন।</h2>
            <p>নাম, মোবাইল নম্বর, সার্ভিস এবং আপনার প্রয়োজন সংক্ষেপে লিখুন। আমরা রিকোয়েস্ট দেখে দ্রুত যোগাযোগ করব।</p>
            <div class="contact-points">
              <div>ফ্ল্যাট/বাসা/শিক্ষক/পিকআপ—সব রিকোয়েস্ট এক ফর্মে</div>
              <div>রিকোয়েস্ট Collection ও পরবর্তী যোগাযোগ সহজ হবে</div>
              <div>প্রয়োজন অনুযায়ী প্রমোশন সেটআপ করা যাবে</div>
            </div>
            <div class="contact-direct">
              <div class="corporate-office-card" style="width: 100%; margin-bottom: 14px; font-weight: 600; color: #1e293b; background: rgba(255,255,255,0.85); padding: 14px 18px; border-radius: 14px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: flex-start; gap: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.03);">
                <span style="font-size: 1.5rem; line-height: 1;">🏢</span>
                <div>
                  <strong style="color: #0f172a; display: block; font-size: 1.05rem; margin-bottom: 3px;">কর্পোরেট অফিস :</strong>
                  <span style="color: #334155; font-size: 0.98rem; line-height: 1.5;">জহির স্মার্ট টাওয়ার, শেওড়াপাড়া, ঢাকা ১২১৬</span>
                </div>
              </div>
              <a class="email" href="mailto:amarthikanaa.info@gmail.com">✉️ amarthikanaa.info@gmail.com</a>
              <a class="whatsapp" href="https://wa.me/8801323351028" target="_blank" rel="noopener">💬 WhatsApp: 01323351028</a>
              <a class="whatsapp" href="tel:+8801323351028">📞 01323351028</a>
            </div>
          </div>

          <form class="lead-form" id="service-request-form">
            <div class="form-grid">
              <label>
                নাম
                <input type="text" name="name" placeholder="আপনার নাম" required>
              </label>
              <label>
                মোবাইল নম্বর
                <input type="tel" name="phone" placeholder="01XXXXXXXXX" required>
              </label>
            </div>
            <div class="form-grid">
              <label>
                সার্ভিস
                <select name="service" required>
                  <option value="">সার্ভিস নির্বাচন করুন</option>
                  <option>ফ্ল্যাট ভাড়া</option>
                  <option>ফ্ল্যাট বিক্রি</option>
                  <option>বাসা খোঁজা</option>
                  <option>শিক্ষক সার্ভিস</option>
                  <option>পিকআপ সার্ভিস</option>
                  <option>সেফটি ও SOS</option>
                  <option>নিরাপদ লেনদেন</option>
                  <option>ডিজিটাল বাজার</option>
                </select>
              </label>
              <label>
                লোকেশন
                <input type="text" name="location" placeholder="যেমন: ঢাকা, চট্টগ্রাম, সিলেট...">
              </label>
            </div>
            <label>
              আপনার প্রয়োজন
              <textarea name="message" placeholder="আপনি কী ধরনের সার্ভিস চান, সংক্ষেপে লিখুন..."></textarea>
            </label>
            <button class="btn btn-primary" type="submit">রিকোয়েস্ট পাঠান</button>
            <p class="form-message" role="status"></p>
          </form>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="final-cta">
          <div class="final-cta-inner">
            <div>
              <h2>একটি স্মার্ট প্ল্যাটফর্ম থেকেই শুরু হোক আপনার সহজ সার্ভিস যাত্রা।</h2>
              <p>AmarThikanaa ব্যবহারকারীকে সঠিক সার্ভিস বুঝতে, আস্থা পেতে এবং দ্রুত রিকোয়েস্ট পাঠাতে সাহায্য করবে।</p>
            </div>
            <a class="btn btn-light" href="#contact">এখনই রিকোয়েস্ট করুন</a>
          </div>
        </div>
      </div>
    </section>
  </main>

  <script>
    (() => {
      const smartBazarSection = document.getElementById("grocery-products");
      const servicesSection = document.getElementById("services");
      if (smartBazarSection && servicesSection) {
        servicesSection.before(smartBazarSection);
      }
    })();
  </script>

  <footer class="site-footer">
    <div class="footer-inner">
      <div class="footer-brand">
        <div class="footer-brand-lockup">
          <img src="amar_thikanaa_icon.png" alt="Amar Thikanaa logo">
          <div>
            <strong>Amar Thikanaa</strong>
            <small>Smart Marketplace &amp; Local Services</small>
          </div>
        </div>
        <p class="footer-description">নিরাপদে পণ্য কেনাবেচা, স্থানীয় ব্যবসার সঙ্গে সরাসরি যোগাযোগ এবং প্রয়োজনীয় সেবা—সবকিছু এখন একটি বিশ্বস্ত প্ল্যাটফর্মে।</p>
      </div>

      <div class="footer-column">
        <h3>দ্রুত লিংক</h3>
        <div class="footer-links">
          <a href="#services">সকল সার্ভিস</a>
          <a href="#grocery-products">Smart Bazar</a>
          <a href="#team-network">টিম ও এজেন্ট নেটওয়ার্ক</a>
          <a href="#how-it-works">কীভাবে কাজ করে</a>
          <a href="#faq">সাধারণ প্রশ্ন</a>
          <a href="#contact">যোগাযোগ</a>
        </div>
      </div>

      <div class="footer-column">
        <h3>আমাদের সঙ্গে যোগাযোগ</h3>
        <div class="footer-contact">
          <div style="display: flex; gap: 10px; align-items: flex-start; margin-bottom: 14px; color: rgba(255,255,255,0.95);">
            <span class="footer-contact-icon" aria-hidden="true" style="font-size: 1.2rem;">🏢</span>
            <span class="footer-contact-text">
              <small style="display: block; color: rgba(255,255,255,0.65); font-size: 0.8rem;">কর্পোরেট অফিস</small>
              <strong style="font-size: 0.95rem; line-height: 1.4;">জহির স্মার্ট টাওয়ার, শেওড়াপাড়া, ঢাকা ১২১৬</strong>
            </span>
          </div>
          <a href="mailto:amarthikanaa.info@gmail.com" aria-label="Email Amar Thikanaa">
            <span class="footer-contact-icon" aria-hidden="true">✉</span>
            <span class="footer-contact-text"><small>Email address</small><strong>amarthikanaa.info@gmail.com</strong></span>
          </a>
          <a class="whatsapp" href="https://wa.me/8801323351028" target="_blank" rel="noopener" aria-label="Chat with Amar Thikanaa on WhatsApp">
            <span class="footer-contact-icon" aria-hidden="true">◉</span>
            <span class="footer-contact-text"><small>Helpline</small><strong>01323351028</strong></span>
          </a>
          <a class="whatsapp" href="https://wa.me/8801956476661" target="_blank" rel="noopener" aria-label="Chat with Amar Thikanaa on WhatsApp">
            <span class="footer-contact-icon" aria-hidden="true">◉</span>
            <span class="footer-contact-text"><small>Helpline</small><strong>01956476661</strong></span>
          </a>
          <a href="tel:+8809658825461" aria-label="Call Amar Thikanaa">
            <span class="footer-contact-icon" aria-hidden="true">📞</span>
            <span class="footer-contact-text"><small>Helpline</small><strong>09658-825461</strong></span>
          </a>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <span>© 2026 Amar Thikanaa. সর্বস্বত্ব সংরক্ষিত।</span>
      <span>নিরাপদ কেনাবেচা · স্থানীয় সেবা · সরাসরি সংযোগ</span>
    </div>
  </footer>

  <div class="live-chat" aria-live="polite">
    <button class="chat-launcher" type="button" aria-label="লাইভ চ্যাট খুলুন" aria-expanded="false">
      <span>লাইভ চ্যাট</span>
      <strong>?</strong>
    </button>

    <section class="chat-panel" aria-label="লাইভ চ্যাট সহায়তা">
      <div class="chat-header">
        <div>
          <strong>আমার ঠিকানা সহায়তা</strong>
          <small>সাধারণত কয়েক মিনিটের মধ্যে রিপ্লাই</small>
        </div>
        <button class="chat-close" type="button" aria-label="লাইভ চ্যাট বন্ধ করুন">×</button>
      </div>

      <!-- Pre-chat form -->
      <div id="chatPreForm" style="padding: 20px;">
        <p style="margin: 0 0 15px; color: var(--muted); font-size: 14px;">চ্যাট শুরু করতে আপনার নাম এবং মোবাইল নম্বর দিন।</p>
        <div style="display: grid; gap: 12px;">
          <input type="text" id="preChatName" placeholder="আপনার পুরো নাম" style="width: 100%; padding: 12px; border: 1px solid var(--border); border-radius: 12px; outline: 0; color: var(--dark);" required>
          <input type="tel" id="preChatMobile" placeholder="মোবাইল নম্বর (যেমন: 01XXXXXXXXX)" style="width: 100%; padding: 12px; border: 1px solid var(--border); border-radius: 12px; outline: 0; color: var(--dark);" required>
          <button id="startChatBtn" type="button" onclick="window.startLiveChat()" style="padding: 12px; background: var(--primary); color: #fff; border: 0; border-radius: 12px; font-weight: 800; cursor: pointer; transition: 0.2s;">চ্যাট শুরু করুন</button>
        </div>
      </div>

      <div class="chat-messages" id="chatMessages" style="display: none;">
        <div class="chat-bubble support">আসসালামু আলাইকুম। আপনি কোন সার্ভিস সম্পর্কে জানতে চান?</div>
      </div>

      <div class="chat-input-area" style="display: none;">
        <div class="chat-quick">
          <button type="button">ফ্ল্যাট ভাড়া</button>
          <button type="button">সার্ভিস রিকোয়েস্ট</button>
          <button type="button">সাপোর্ট দরকার</button>
        </div>

        <form class="chat-form">
          <input type="text" name="message" placeholder="আপনার মেসেজ লিখুন..." autocomplete="off" required>
          <button type="submit">পাঠান</button>
        </form>
      </div>
    </section>
  </div>

  <script src="/js/bn-ui.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/microsoft-signalr/6.0.1/signalr.min.js"></script>
  <script>
    const header = document.querySelector('.site-header');
    const navToggle = document.querySelector('.nav-toggle');
    const navLinks = document.querySelectorAll('.nav-links a');

    navToggle?.addEventListener('click', () => {
      const isOpen = header.classList.toggle('menu-open');
      navToggle.setAttribute('aria-expanded', String(isOpen));
    });

    navLinks.forEach(link => {
      link.addEventListener('click', () => {
        header.classList.remove('menu-open');
        navToggle?.setAttribute('aria-expanded', 'false');
      });
    });

    const sections = [...document.querySelectorAll('main section[id]')];
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          document.querySelectorAll('.nav-links a').forEach(a => a.classList.remove('active'));
          const active = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
          active?.classList.add('active');
        }
      });
    }, { rootMargin: '-45% 0px -48% 0px' });
    sections.forEach(section => observer.observe(section));

    const revealGroups = [
      '.section-heading',
      '.network-stats-heading',
      '.service-card',
      '.grocery-feature',
      '.product-card',
      '.trust-item',
      '.split-section > *',
      '.step-item',
      '.process-card',
      '.audience-card',
      '.highlight-card',
      '.faq-side',
      '.faq-item',
      '.contact-section > *',
      '.final-cta',
      '.footer-inner > *'
    ];
    const revealItems = document.querySelectorAll(revealGroups.join(','));

    revealItems.forEach((item, index) => {
      item.classList.add('reveal');
      if (item.matches('.split-section > :first-child, .faq-side, .contact-section > :first-child')) {
        item.classList.add('reveal-left');
      }
      if (item.matches('.split-section > :last-child, .contact-section > :last-child')) {
        item.classList.add('reveal-right');
      }
      item.style.setProperty('--reveal-delay', `${(index % 4) * 85}ms`);
    });

    if ('IntersectionObserver' in window) {
      const revealObserver = new IntersectionObserver(entries => {
        entries.forEach(entry => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add('is-visible');
          revealObserver.unobserve(entry.target);
        });
      }, { threshold: 0.12, rootMargin: '0px 0px -45px' });

      revealItems.forEach(item => revealObserver.observe(item));
    } else {
      revealItems.forEach(item => item.classList.add('is-visible'));
    }

    const $networkSection = $('#network-stats');
    let networkStatsLoaded = false;

    function animateNetworkCount($element, target) {
      const duration = window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 1300;
      const startTime = performance.now();
      const formatter = new Intl.NumberFormat('en-BD');

      function update(currentTime) {
        const progress = duration === 0 ? 1 : Math.min((currentTime - startTime) / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        $element.text(formatter.format(Math.round(target * eased)));
        if (progress < 1) requestAnimationFrame(update);
      }

      requestAnimationFrame(update);
    }

    function loadNetworkStats() {
      if (networkStatsLoaded) return;
      networkStatsLoaded = true;

      $.ajax({
        url: '/Home/NetworkStats',
        method: 'GET',
        dataType: 'json',
        cache: false
      }).done(function (stats) {
        $('.network-stat-card').each(function (index) {
          const $card = $(this);
          const $count = $card.find('.network-count');
          const value = Number(stats[$count.data('key')]) || 0;

          setTimeout(function () {
            $card.addClass('is-visible');
            animateNetworkCount($count, value);
          }, index * 120);
        });
        $('.network-stats-status').text('সর্বশেষ হিসাব দেখানো হচ্ছে');
      }).fail(function () {
        networkStatsLoaded = false;
        $('.network-stats-status').text('Network data এখন লোড করা যাচ্ছে না। কিছুক্ষণ পর আবার চেষ্টা করুন।');
      });
    }

    if ($networkSection.length && 'IntersectionObserver' in window) {
      const networkObserver = new IntersectionObserver(function (entries, observerInstance) {
        if (!entries.some(entry => entry.isIntersecting)) return;
        loadNetworkStats();
        observerInstance.disconnect();
      }, { threshold: .2 });
      networkObserver.observe($networkSection[0]);
    } else {
      loadNetworkStats();
    }

    document.querySelectorAll('.service-card').forEach(card => {
      card.addEventListener('click', event => {
        if (event.target.closest('a')) return;
        const service = card.dataset.service;
        const select = document.querySelector('.lead-form select[name="service"]');
        if (select && service) select.value = service;
        document.querySelector('#contact')?.scrollIntoView({ behavior: 'smooth' });
      });
    });

    document.querySelectorAll('.faq-question').forEach(button => {
      button.addEventListener('click', () => {
        const item = button.closest('.faq-item');
        const isOpen = item.classList.toggle('open');
        button.querySelector('span').textContent = isOpen ? '−' : '+';
      });
    });

    $('#service-request-form').on('submit', function (event) {
      event.preventDefault();
      const $form = $(this);
      const $button = $form.find('button[type="submit"]');
      const $message = $form.find('.form-message');
      const data = Object.fromEntries(new FormData(this).entries());

      $button.prop('disabled', true);
      $message.css('color', '#40516b').text('রিকোয়েস্ট পাঠানো হচ্ছে...');

      $.ajax({
        url: '/api/service-requests',
        method: 'POST',
        contentType: 'application/json; charset=utf-8',
        data: JSON.stringify(data)
      }).done(function () {
        $message.css('color', '#059669').text('ধন্যবাদ! আপনার রিকোয়েস্ট গ্রহণ করা হয়েছে। খুব দ্রুত যোগাযোগ করা হবে।');
        $form[0].reset();
      }).fail(function (xhr) {
        const validationErrors = xhr.responseJSON?.errors;
        const firstError = validationErrors
          ? Object.values(validationErrors).flat()[0]
          : null;
        $message.css('color', '#dc2626').text(firstError || 'রিকোয়েস্ট পাঠানো যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।');
      }).always(function () {
        $button.prop('disabled', false);
      });
    });

    const liveChat = document.querySelector('.live-chat');
    const chatLauncher = document.querySelector('.chat-launcher');
    const chatClose = document.querySelector('.chat-close');
    const chatPreForm = document.getElementById('chatPreForm');
    const chatMessagesEl = document.getElementById('chatMessages');
    const chatInputAreaEl = document.querySelector('.chat-input-area');
    const chatForm = document.querySelector('.chat-form');

    function toggleChat(open) {
      liveChat.classList.toggle('open', open);
      chatLauncher.setAttribute('aria-expanded', String(open));
    }
    chatLauncher?.addEventListener('click', () => toggleChat(!liveChat.classList.contains('open')));
    chatClose?.addEventListener('click', () => toggleChat(false));

    // --- Live chat: real-time connection to the support team via SignalR ---
    const LIVE_CHAT_SESSION_KEY = 'liveChatSessionId';
    const LIVE_CHAT_NAME_KEY = 'liveChatUserName';
    const LIVE_CHAT_PHONE_KEY = 'liveChatUserPhone';

    let chatConnection = null;
    let chatSessionId = null;
    let chatJoined = false;
    let supportAgentConnected = false;
    let connectingNoticeShown = false;
    const receivedChatMessageIds = new Set();

    function ensureChatSessionId() {
      let id = localStorage.getItem(LIVE_CHAT_SESSION_KEY);
      if (!id) {
        id = (window.crypto && crypto.randomUUID)
          ? crypto.randomUUID()
          : `sess-${Date.now()}-${Math.random().toString(36).slice(2)}`;
        localStorage.setItem(LIVE_CHAT_SESSION_KEY, id);
      }
      return id;
    }

    function appendSystemNotice(text) {
      const bubble = document.createElement('div');
      bubble.className = 'chat-bubble support';
      bubble.textContent = text;
      chatMessagesEl.appendChild(bubble);
      chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
    }

    function appendChatMessage(msg) {
      if (msg.messageId && receivedChatMessageIds.has(msg.messageId)) return;
      if (msg.messageId) receivedChatMessageIds.add(msg.messageId);
      if (msg.senderType === 'Agent') {
        supportAgentConnected = true;
        chatMessagesEl.querySelector('.chat-bubble.connecting')?.remove();
      }
      const bubble = document.createElement('div');
      bubble.className = 'chat-bubble ' + (msg.senderType === 'Agent' ? 'support' : 'user');
      bubble.textContent = msg.messageText;
      chatMessagesEl.appendChild(bubble);
      chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
    }

    function showSupportConnectingNotice() {
      if (supportAgentConnected || connectingNoticeShown) return;
      connectingNoticeShown = true;

      const bubble = document.createElement('div');
      bubble.className = 'chat-bubble support connecting';
      bubble.innerHTML = `
        <strong>সাপোর্ট টিমের সঙ্গে সংযোগ করা হচ্ছে<span class="connecting-dots" aria-hidden="true"><i></i><i></i><i></i></span></strong>
        <span>আপনার মেসেজটি আমরা পেয়েছি। একজন সাপোর্ট প্রতিনিধি আপনার সঙ্গে যুক্ত হচ্ছেন—অনুগ্রহ করে একটু অপেক্ষা করুন।</span>`;
      chatMessagesEl.appendChild(bubble);
      chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
    }

    function renderChatHistory(messages) {
      chatMessagesEl.innerHTML = '';
      receivedChatMessageIds.clear();
      supportAgentConnected = Boolean(messages?.some(message => message.senderType === 'Agent'));
      if (!messages || messages.length === 0) {
        appendSystemNotice('আসসালামু আলাইকুম। আপনি কোন সার্ভিস সম্পর্কে জানতে চান?');
        return;
      }
      messages.forEach(appendChatMessage);
    }

    async function getChatConnection() {
      if (chatConnection) return chatConnection;

      chatConnection = new signalR.HubConnectionBuilder()
        .withUrl('/hubs/live-support', {
          // The production IIS host rejects SignalR's default text/plain POSTs.
          // Sending JSON keeps negotiate, fallback transports and hub messages
          // on a content type accepted by the host.
          headers: { 'Content-Type': 'application/json' }
        })
        .withAutomaticReconnect()
        .build();

      chatConnection.on('LoadHistory', renderChatHistory);
      chatConnection.on('ReceiveMessage', appendChatMessage);
      chatConnection.on('AgentJoined', agent => {
        supportAgentConnected = true;
        chatMessagesEl.querySelector('.chat-bubble.connecting')?.remove();
        appendSystemNotice(`${agent?.name || 'সাপোর্ট এজেন্ট'} চ্যাটে যুক্ত হয়েছেন।`);
      });
      chatConnection.on('SessionResolved', () => {
        appendSystemNotice('এই চ্যাট সমাধান করা হয়েছে। নতুন সহায়তার প্রয়োজন হলে আবার মেসেজ পাঠান।');
        resetLiveChatSession();
      });
      chatConnection.on('SessionClosed', resetLiveChatSession);
      chatConnection.onreconnected(async () => {
        const name = localStorage.getItem(LIVE_CHAT_NAME_KEY);
        const phone = localStorage.getItem(LIVE_CHAT_PHONE_KEY);
        if (chatSessionId && name && phone) {
          chatJoined = await chatConnection.invoke('JoinSession', chatSessionId, name, phone);
        }
      });
      chatConnection.onclose(() => {
        chatJoined = false;
        chatConnection = null;
      });

      await chatConnection.start();
      return chatConnection;
    }

    async function joinLiveChat(name, phone) {
      chatSessionId = ensureChatSessionId();
      localStorage.setItem(LIVE_CHAT_NAME_KEY, name);
      localStorage.setItem(LIVE_CHAT_PHONE_KEY, phone);

      const connection = await getChatConnection();
      chatJoined = await connection.invoke('JoinSession', chatSessionId, name, phone);
      if (!chatJoined) return;

      chatPreForm.style.display = 'none';
      chatMessagesEl.style.display = 'flex';
      chatInputAreaEl.style.display = 'block';
    }

    function resetLiveChatSession() {
      chatJoined = false;
      supportAgentConnected = false;
      connectingNoticeShown = false;
      chatSessionId = null;
      localStorage.removeItem(LIVE_CHAT_SESSION_KEY);
      localStorage.removeItem(LIVE_CHAT_NAME_KEY);
      localStorage.removeItem(LIVE_CHAT_PHONE_KEY);
      chatInputAreaEl.style.display = 'none';
      chatPreForm.style.display = 'block';
    }

    window.startLiveChat = async function () {
      const btn = document.getElementById('startChatBtn');
      const nameInput = document.getElementById('preChatName');
      const mobileInput = document.getElementById('preChatMobile');

      const name = nameInput?.value.trim();
      const mobile = mobileInput?.value.trim();
      if (!name || !/^01\d{9}$/.test(mobile)) {
        alert('দয়া করে আপনার নাম এবং সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।');
        return;
      }

      const originalText = btn.innerText;
      btn.innerText = 'অপেক্ষা করুন...';
      btn.disabled = true;

      try {
        // Best-effort lead record; the real-time chat below doesn't depend on it.
        fetch('/api/LiveChatApi/start', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ FullName: name, MobileNumber: mobile })
        }).catch(() => {});

        await joinLiveChat(name, mobile);
        btn.innerText = originalText;
        btn.disabled = false;
      } catch (err) {
        console.error(err);
        alert('সংযোগ করা যাচ্ছে না। দয়া করে আবার চেষ্টা করুন।');
        btn.innerText = originalText;
        btn.disabled = false;
      }
    };

    document.querySelectorAll('.chat-quick button').forEach(btn => {
      btn.addEventListener('click', () => {
        chatForm.message.value = btn.textContent.trim();
        chatForm.requestSubmit();
      });
    });

    chatForm?.addEventListener('submit', async event => {
      event.preventDefault();
      const text = chatForm.message.value.trim();
      if (!text || !chatJoined || !chatConnection) return;

      if (text.length > 2000) {
        appendSystemNotice('মেসেজ সর্বোচ্চ ২০০০ অক্ষরের হতে পারবে।');
        return;
      }

      chatForm.message.value = '';
      const sendButton = chatForm.querySelector('button[type="submit"]');
      sendButton.disabled = true;
      try {
        await chatConnection.invoke('SendGuestMessage', chatSessionId, text);
        showSupportConnectingNotice();
      } catch (err) {
        console.error(err);
        chatForm.message.value = text;
        appendSystemNotice('মেসেজ পাঠানো যায়নি। আবার চেষ্টা করুন।');
      } finally {
        sendButton.disabled = false;
      }
    });

    // Resume an already-started chat (e.g. after a page refresh) so history + replies keep loading.
    (function resumeLiveChatIfAny() {
      const savedName = localStorage.getItem(LIVE_CHAT_NAME_KEY);
      const savedPhone = localStorage.getItem(LIVE_CHAT_PHONE_KEY);
      if (savedName && savedPhone) {
        joinLiveChat(savedName, savedPhone).catch(err => console.error(err));
      }
    })();

    // --- District leaderboard: top 50 buyers / top 50 shopkeepers per district ---
    (function initDistrictLeaderboard() {
      const districtSelect = document.getElementById('leaderboardDistrict');
      const buyersList = document.getElementById('topBuyersList');
      const shopkeepersList = document.getElementById('topShopkeepersList');
      if (!districtSelect || !buyersList || !shopkeepersList) return;

      const currency = new Intl.NumberFormat('en-BD');

      function renderList(el, entries, secondaryLabelPrefix) {
        el.innerHTML = '';
        if (!Array.isArray(entries) || entries.length === 0) {
          const empty = document.createElement('li');
          empty.className = 'leaderboard-empty';
          empty.textContent = 'এখনো কোনো তথ্য নেই।';
          el.appendChild(empty);
          return;
        }

        entries.forEach(entry => {
          const row = document.createElement('li');
          row.className = 'leaderboard-row' + (entry.rank <= 3 ? ` rank-${entry.rank}` : '');

          const rank = document.createElement('div');
          rank.className = 'leaderboard-rank';
          rank.textContent = entry.rank;

          const name = document.createElement('div');
          name.className = 'leaderboard-name';
          const strong = document.createElement('strong');
          strong.textContent = entry.name;
          name.appendChild(strong);
          if (entry.secondaryLabel) {
            const small = document.createElement('small');
            small.textContent = `${secondaryLabelPrefix}${entry.secondaryLabel}`;
            name.appendChild(small);
          }

          const amount = document.createElement('div');
          amount.className = 'leaderboard-amount';
          amount.textContent = `৳${currency.format(Math.round(entry.totalAmount))}`;

          row.append(rank, name, amount);
          el.appendChild(row);
        });
      }

      function loadLeaderboards(districtId) {
        buyersList.innerHTML = '<li class="leaderboard-empty">লোড হচ্ছে...</li>';
        shopkeepersList.innerHTML = '<li class="leaderboard-empty">লোড হচ্ছে...</li>';

        fetch(`/Home/TopBuyers?districtId=${districtId}`)
          .then(response => response.ok ? response.json() : [])
          .then(entries => renderList(buyersList, entries, ''))
          .catch(() => renderList(buyersList, []));

        fetch(`/Home/TopShopkeepers?districtId=${districtId}`)
          .then(response => response.ok ? response.json() : [])
          .then(entries => renderList(shopkeepersList, entries, 'মালিক: '))
          .catch(() => renderList(shopkeepersList, []));
      }

      districtSelect.addEventListener('change', () => {
        if (districtSelect.value) loadLeaderboards(districtSelect.value);
      });

      fetch('/Home/Districts')
        .then(response => response.ok ? response.json() : [])
        .then(districts => {
          districtSelect.innerHTML = '';
          if (!Array.isArray(districts) || districts.length === 0) {
            districtSelect.innerHTML = '<option value="">জেলার তথ্য পাওয়া যায়নি</option>';
            return;
          }

          districts.forEach(district => {
            const option = document.createElement('option');
            option.value = district.id;
            option.textContent = district.name;
            districtSelect.appendChild(option);
          });

          districtSelect.value = districts[0].id;
          loadLeaderboards(districts[0].id);
        })
        .catch(() => {
          districtSelect.innerHTML = '<option value="">জেলার তথ্য লোড করা যায়নি</option>';
        });
    })();

    fetch('/Home/Bulletins')
      .then(response => response.ok ? response.json() : [])
      .then(bulletins => {
        if (!Array.isArray(bulletins) || bulletins.length === 0) return;

        const bulletinBar = document.getElementById('landing-bulletin');
        const bulletinTrack = document.getElementById('landing-bulletin-track');
        bulletins.forEach((bulletin, index) => {
          if (index > 0 || bulletinTrack.children.length > 0) {
            const separator = document.createElement('span');
            separator.className = 'landing-bulletin-separator';
            separator.textContent = '\u2022';
            bulletinTrack.appendChild(separator);
          }

          const message = document.createElement(bulletin.linkUrl ? 'a' : 'span');
          message.textContent = bulletin.message;
          if (bulletin.linkUrl) {
            message.href = bulletin.linkUrl;
            message.target = '_blank';
            message.rel = 'noopener';
          }
          bulletinTrack.appendChild(message);
        });

        const duration = Math.max(18, bulletins.reduce((total, item) => total + item.message.length, 0) / 5);
        bulletinTrack.style.setProperty('--bulletin-duration', `${duration}s`);
        bulletinBar.classList.add('is-visible');
      })
      .catch(() => {});

    // Team & Field Network Directory
    (function initTeamDirectory() {
      const grid = document.getElementById('teamDirectoryGrid');
      const districtSelect = document.getElementById('teamDistrictFilter');
      const searchInput = document.getElementById('teamSearchInput');
      const tabButtons = document.querySelectorAll('.team-tab-btn');
      if (!grid) return;

      let allMembers = [];
      let currentRole = 'all';
      let currentDistrict = '';
      let currentSearch = '';

      const fallbackMembers = [
        {
          id: 1,
          name: 'মোঃ রফিকুল ইসলাম',
          phone: '01711000001',
          role: 'Agent',
          roleTitle: 'এরিয়া এজেন্ট',
          districtId: 1,
          districtName: 'ঢাকা (মিরপুর ও উত্তরা)',
          connectedCount: 45,
          connectedLabel: '৪৫+ ভেরিফাইড শপ',
          rating: 4.9,
          profilePictureUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80'
        },
        {
          id: 2,
          name: 'তানভীর আহমেদ',
          phone: '01812000002',
          role: 'FieldOfficer',
          roleTitle: 'ফিল্ড অফিসার',
          districtId: 1,
          districtName: 'ঢাকা (মিরপুর)',
          parentName: 'এজেন্ট: মোঃ রফিকুল ইসলাম',
          connectedCount: 22,
          connectedLabel: '২২+ সক্রিয় শপ',
          rating: 4.8,
          profilePictureUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80'
        },
        {
          id: 3,
          name: 'আব্দুল কাদের',
          phone: '01913000003',
          role: 'Agent',
          roleTitle: 'এরিয়া এজেন্ট',
          districtId: 4,
          districtName: 'চট্টগ্রাম (কোতোয়ালি ও আগ্রাবাদ)',
          connectedCount: 38,
          connectedLabel: '৩৮+ ভেরিফাইড শপ',
          rating: 5.0,
          profilePictureUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80'
        },
        {
          id: 4,
          name: 'মাহমুদুল হাসান',
          phone: '01714000004',
          role: 'FieldOfficer',
          roleTitle: 'ফিল্ড অফিসার',
          districtId: 4,
          districtName: 'চট্টগ্রাম (আগ্রাবাদ)',
          parentName: 'এজেন্ট: আব্দুল কাদের',
          connectedCount: 16,
          connectedLabel: '১৬+ সক্রিয় শপ',
          rating: 4.9,
          profilePictureUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80'
        },
        {
          id: 5,
          name: 'সাইফুল ইসলাম',
          phone: '01515000005',
          role: 'Agent',
          roleTitle: 'এরিয়া এজেন্ট',
          districtId: 12,
          districtName: 'সিলেট (সদর ও শাহজালাল উপশহর)',
          connectedCount: 30,
          connectedLabel: '৩০+ ভেরিফাইড শপ',
          rating: 4.9,
          profilePictureUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80'
        },
        {
          id: 6,
          name: 'মেহেদী হাসান রনি',
          phone: '01616000006',
          role: 'FieldOfficer',
          roleTitle: 'ফিল্ড অফিসার',
          districtId: 12,
          districtName: 'সিলেট (উপশহর)',
          parentName: 'এজেন্ট: সাইফুল ইসলাম',
          connectedCount: 14,
          connectedLabel: '১৪+ সক্রিয় শপ',
          rating: 4.7,
          profilePictureUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80'
        }
      ];

      function renderMembers() {
        let filtered = allMembers.filter(m => {
          const matchRole = currentRole === 'all' || m.role.toLowerCase() === currentRole.toLowerCase();
          const matchDistrict = !currentDistrict || String(m.districtId) === String(currentDistrict) || (m.districtName && m.districtName.toLowerCase().includes(currentDistrict.toLowerCase()));
          const s = currentSearch.toLowerCase().trim();
          const matchSearch = !s || (m.name && m.name.toLowerCase().includes(s)) ||
                                     (m.phone && m.phone.includes(s)) ||
                                     (m.districtName && m.districtName.toLowerCase().includes(s)) ||
                                     (m.roleTitle && m.roleTitle.toLowerCase().includes(s));
          return matchRole && matchDistrict && matchSearch;
        });

        if (filtered.length === 0) {
          grid.innerHTML = `
            <div style="grid-column: 1 / -1; padding: 40px 20px; text-align: center; background: #f8fafc; border-radius: 16px; color: var(--muted);">
              <p style="font-size: 16px; font-weight: 700; margin: 0 0 6px; color: var(--dark);">কোনো প্রতিনিধি পাওয়া যায়নি</p>
              <small>অনুগ্রহ করে ভিন্ন জেলা বা ফিল্টার নির্বাচন করে পুনরায় চেষ্টা করুন।</small>
            </div>
          `;
          return;
        }

        grid.innerHTML = filtered.map(m => {
          const isAgent = m.role.toLowerCase() === 'agent';
          const avatarHtml = m.profilePictureUrl
            ? `<img class="team-avatar-img" src="${m.profilePictureUrl}" alt="${m.name}" onerror="this.outerHTML='<div class=\\'team-avatar-fallback ${isAgent ? 'agent' : 'field'}\\'>${m.name ? m.name.charAt(0) : 'A'}</div>'">`
            : `<div class="team-avatar-fallback ${isAgent ? 'agent' : 'field'}">${m.name ? m.name.charAt(0) : 'A'}</div>`;

          const cleanPhone = m.phone ? m.phone.replace(/[^0-9+]/g, '') : '';
          const waPhone = cleanPhone.startsWith('0') ? '88' + cleanPhone : cleanPhone;

          return `
            <div class="team-card">
              <div class="team-card-top">
                <div class="team-avatar-box">
                  ${avatarHtml}
                  <span class="team-verified-badge" title="ভেরিফাইড অফিশিয়াল প্রতিনিধি">✓</span>
                </div>
                <div class="team-info-header">
                  <span class="team-role-tag ${isAgent ? 'agent' : 'field'}">
                    ${isAgent ? '👑 এরিয়া এজেন্ট' : '🛡️ ফিল্ড অফিসার'}
                  </span>
                  <h3 class="team-name" title="${m.name}">${m.name}</h3>
                  <div class="team-location">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M12 2a8 8 0 0 0-8 8c0 5.25 8 12 8 12s8-6.75 8-12a8 8 0 0 0-8-8z"/><circle cx="12" cy="10" r="3"/></svg>
                    <span>${m.districtName || 'বাংলাদেশ'}</span>
                  </div>
                </div>
              </div>

              <div class="team-meta-box">
                <div class="team-meta-item">
                  <span class="team-meta-label">${isAgent ? 'নেটওয়ার্ক পরিধি' : 'মাঠ কার্যক্রম'}</span>
                  <span class="team-meta-value">${m.connectedLabel || (isAgent ? 'এরিয়া ইনচার্জ' : 'সক্রিয় প্রতিনিধি')}</span>
                </div>
                <div class="team-meta-rating">
                  ⭐ <span>${m.rating ? m.rating.toFixed(1) : '4.9'}</span>
                </div>
              </div>

              ${m.parentName ? `<div style="font-size: 11.5px; color: var(--muted); margin-bottom: 12px; font-weight: 600;">🔗 ${m.parentName}</div>` : ''}

              <div class="team-card-actions">
                <a class="team-btn-call" href="tel:${cleanPhone}">
                  📞 কল করুন
                </a>
                <a class="team-btn-whatsapp" href="https://wa.me/${waPhone}" target="_blank" rel="noopener">
                  💬 WhatsApp
                </a>
              </div>
            </div>
          `;
        }).join('');
      }

      function loadData() {
        fetch('/Home/TeamDirectory')
          .then(res => res.ok ? res.json() : [])
          .then(data => {
            if (Array.isArray(data) && data.length > 0) {
              allMembers = data;
            } else {
              allMembers = fallbackMembers;
            }
            renderMembers();
          })
          .catch(() => {
            allMembers = fallbackMembers;
            renderMembers();
          });
      }

      fetch('/Home/Districts')
        .then(res => res.ok ? res.json() : [])
        .then(districts => {
          if (districtSelect && Array.isArray(districts) && districts.length > 0) {
            districts.forEach(d => {
              const opt = document.createElement('option');
              opt.value = d.id;
              opt.textContent = d.name;
              districtSelect.appendChild(opt);
            });
          }
        })
        .catch(() => {});

      tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
          tabButtons.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          currentRole = btn.getAttribute('data-role') || 'all';
          renderMembers();
        });
      });

      if (districtSelect) {
        districtSelect.addEventListener('change', () => {
          currentDistrict = districtSelect.value;
          renderMembers();
        });
      }

      if (searchInput) {
        searchInput.addEventListener('input', (e) => {
          currentSearch = e.target.value;
          renderMembers();
        });
      }

      loadData();
    })();

    // Language Switcher (BN / EN)
    (function initLanguageSwitcher() {
      const btn = document.getElementById('lang-toggle-btn');
      if (!btn) return;
      let currentLang = localStorage.getItem('amar_thikanaa_lang') || 'bn';

      function updateLanguage(lang) {
        currentLang = lang;
        localStorage.setItem('amar_thikanaa_lang', lang);
        btn.textContent = lang === 'bn' ? '🌐 EN' : '🌐 BN';

        document.querySelectorAll('[data-bn][data-en]').forEach(el => {
          el.textContent = lang === 'bn' ? el.getAttribute('data-bn') : el.getAttribute('data-en');
        });
      }

      btn.addEventListener('click', () => {
        updateLanguage(currentLang === 'bn' ? 'en' : 'bn');
      });

      if (currentLang === 'en') {
        updateLanguage('en');
      }
    })();

    // Typing Animation
    const typingText = "খুঁজুন, কিনুন, বিক্রি করুন, সেবা নিন—সব এক ঠিকানায়, Amar Thikanaa.";
    const targetElement = document.querySelector("#typing-heading .typing-text");
    let index = 0;

    function typeCharacter() {
      if (targetElement && index < typingText.length) {
        targetElement.textContent += typingText.charAt(index);
        index++;
        setTimeout(typeCharacter, 100);
      } else {
        setTimeout(() => {
          const cursor = document.querySelector("#typing-heading .typing-cursor");
          if (cursor) cursor.style.display = 'none';
        }, 5000);
      }
    }
    setTimeout(typeCharacter, 500);
  </script>
</body>
</html>
