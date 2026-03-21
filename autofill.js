// ============================================================
//  FB Recovery OTP Autofill
//  v2.0 — Decodo session-rotation, mbasic-first, 5x SMS loop
//  Usage: node autofill.js numbers.txt [proxy.txt] [workers] [lang] [mode]
//  Modes: decodo | custom | direct
// ============================================================

// ┌─────────────────────────────────────────────────────┐
// │           BRIGHT DATA CONFIG                        │
// └─────────────────────────────────────────────────────┘
// └─────────────────────────────────────────────────────┘

const fs = require('fs');
const path = require('path');
const { Worker } = require('worker_threads');
const os = require('os');
const http = require('http');
const https = require('https');

let SUCCESSFUL_FILE = 'successful.txt';
let FAILED_FILE = 'failed.txt';
let LOG_FILE = 'log.txt';
let DEBUG_FILE = 'debug.txt';
let PROGRESS_FILE = 'progress.json';
let NO_SMS_FILE = 'no_sms.txt';

// ── Domain list: mbasic first (simplest DOM, most reliable SMS detection) ──
// mbasic → m → www. Language subdomains removed (they add noise not value).
const FB_DOMAINS_BY_LANGUAGE = {
    'en': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'es': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'fr': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'de': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'pt': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'it': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'ar': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'hi': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'bn': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'id': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ],
    'ru': [
        'https://mbasic.facebook.com',
        'https://m.facebook.com',
        'https://www.facebook.com',
    ]
};

const DEFAULT_USER_AGENTS = [
    // Android Mobile - High Success Rate (prioritized)
    'Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 12; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 11; SM-A505F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 9; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Mobile Safari/537.36',

    // iPhone - High Success Rate
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',

    // iPad - Tablet Recovery
    'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',

    // Windows Desktop - Lower Priority
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.112 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.6167.85 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',

    // Mac Desktop
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',

    // Linux Desktop
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
];

// Generate fresh user agents for each run, categorized by type
function generateFreshUserAgents() {
    const mobileAgents = [
        // Latest Android 2024
        'Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 12; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',

        // Latest iPhone 2024
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.7 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1',

        // Latest iPad 2024
        'Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPad; CPU OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (iPad; CPU OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',

    ];

    const desktopAgents = [
        // Latest Desktop 2024
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
    ];

    // Add some randomness by shuffling and selecting subsets
    const shuffle = (arr) => [...arr].sort(() => Math.random() - 0.5);
    
    return {
        mobile: shuffle(mobileAgents).slice(0, 20),
        desktop: shuffle(desktopAgents).slice(0, 10)
    };
}

let stats = { success: 0, noAccount: 0, noSms: 0, errors: 0, total: 0, done: 0, rateLimited: 0, captcha: 0 };
let dashboardLinesDrawn = false;
let processingStarted = false;

// ── Proxy pipeline state (used by ProxyManager below) ───────────
let proxyManager = null;  // set in main() when auto mode chosen

// ── Feature 5: Resume state ───────────────────────────────────
let processedNumbers = new Set();

// ── Feature 6: Rate limit state ───────────────────────────────
let rateLimitPause = false;
let consecutiveErrors = 0;
const RATELIMIT_PAUSE_MS = 30000; // pause 30s when rate limited


// Enhanced rate limit detection patterns
const RATELIMIT_SIGNALS = [
    'too many requests', 'try again later', 'temporarily blocked',
    'you have been blocked', 'rate limit', 'too many attempts',
    'please wait', 'সাময়িকভাবে অবরুদ্ধ', 'suspicious activity',
    'unusual activity', 'security check', 'automated requests',
    'facebook.com está bloqueado', 'access denied', 'forbidden',
    'service unavailable', 'server error', 'connection failed'
];

// ── Smart retry configuration ───────────────────────────────────
const RETRY_DELAYS = [30000, 60000, 120000]; // Much longer delays: 30s, 1min, 2min
const MAX_RETRY_ATTEMPTS = 3; // Fewer retries to avoid detection

// ── Dashboard throttling ───────────────────────────────────────
let lastDashboardUpdate = 0;
const DASHBOARD_THROTTLE_MS = 100; // update dashboard max 10fps

// ── Terminal helpers ──────────────────────────────────────────
const W = () => process.stdout.columns || 70;
const line = (c = '─') => c.repeat(W());

function pad(str, len) {
    str = String(str);
    return str.length >= len ? str.slice(0, len) : str + ' '.repeat(len - str.length);
}

function clearScreen() { process.stdout.write('\x1b[2J\x1b[H'); }

function updateTitle() {
    const pct = stats.total > 0 ? Math.round((stats.done / stats.total) * 100) : 0;
    process.stdout.write(`\x1b]0;OTP | ✅${stats.success} ⛔${stats.noAccount} ❌${stats.errors} | ${stats.done}/${stats.total} (${pct}%)\x07`);
}

function drawDashboard() {
    const pct = stats.total > 0 ? Math.round((stats.done / stats.total) * 100) : 0;
    
    const bw = 30; // progress bar length
    const filled = Math.round((pct / 100) * bw);
    const bar = '\x1b[38;5;39m' + '█'.repeat(filled) + '\x1b[38;5;237m' + '░'.repeat(bw - filled) + '\x1b[0m';
    const paused = rateLimitPause ? '\x1b[31;1m [PAUSED-RL]\x1b[0m' : '';
    const proxyCount = proxyManager ? proxyManager.totalVerified : 0;

    const memUsed = Math.round((os.totalmem() - os.freemem()) / 1024 / 1024 / 1024 * 10) / 10;
    const memTotal = Math.round(os.totalmem() / 1024 / 1024 / 1024);
    const hwStr = `\x1b[38;5;244m💻 CPU: ${os.cpus().length}c | RAM: ${memUsed}/${memTotal}GB\x1b[0m`;

    const out = [];
    out.push('');
    out.push(`  \x1b[1;36mFB Auto Recovery\x1b[0m  ${hwStr}  ${paused}`);
    out.push(`  ${bar} \x1b[1;37m${pct}%\x1b[0m  \x1b[38;5;244m(${stats.done}/${stats.total} Numbers)\x1b[0m`);
    out.push('');
    out.push(`  \x1b[38;5;82m✔ Success: ${pad(stats.success, 4)}\x1b[0m  |  \x1b[38;5;203m⛔ No Acc: ${pad(stats.noAccount, 4)}\x1b[0m  |  \x1b[38;5;214m⚠ No SMS: ${pad(stats.noSms, 4)}\x1b[0m`);
    out.push(`  \x1b[38;5;160m✖ Errors : ${pad(stats.errors, 4)}\x1b[0m  |  \x1b[38;5;39m⚡ Proxy : ${pad(proxyCount, 4)}\x1b[0m  |  \x1b[38;5;13m🤖 Captcha: ${pad(stats.captcha, 4)}\x1b[0m`);
    out.push('');

    if (dashboardLinesDrawn) {
        process.stdout.write('\x1b[7A\x1b[J'); // move up 7 lines
    } else {
        dashboardLinesDrawn = true;
    }
    process.stdout.write(out.join('\n') + '\n');
}

function addLog(msg) {
    const display = msg.length > W() - 2 ? msg.slice(0, W() - 5) + '...' : msg;
    
    if (dashboardLinesDrawn) {
        process.stdout.write('\x1b[4A\x1b[J');
        dashboardLinesDrawn = false;
    }
    
    process.stdout.write(display + '\n');
    if (processingStarted) {
        drawDashboard();
        updateTitle();
    }
}

function debug(msg) {
    try {
        fs.appendFileSync(DEBUG_FILE, `[${new Date().toISOString()}] ${msg}\n`);
    } catch (e) {
        console.error('Failed to write debug:', e.message);
    }
}

function moveCursorUp(lines) {
    if (lines > 0) {
        process.stdout.write(`\x1b[${lines}A`);
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ProxyManager — Three modes:
//
//  'freeproxy'  — Fetches fresh proxies from github/proxyscrape.
//                 Tests up to 300 in parallel to build a working pool.
//
//  'custom'     — Load proxies from a text file (host:port:user:pass format).
//                 Rotates through the list, 1 IP per number.
//
//  'direct'     — No proxy. Direct connection.
//
// Checker: upgraded to real HTTP CONNECT tunnel test (reads '200 Connection
// established' response line) — confirms proxy can actually relay HTTPS, 
// not just open a TCP socket.
// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════
//  ProxyManager — Pipeline Architecture (Enhanced Backup Version)
//  Producer: background checker tests scraped proxies in parallel
//  Consumer: OTP workers pull exactly 1 verified proxy per number
//  1 IP = 1 number strictly (proxy popped from queue, never reused)
// ══════════════════════════════════════════════════════════════════
class ProxyManager {
    constructor(mode = 'freeproxy', customList = []) {
        this.mode = mode; // 'freeproxy' or 'custom'
        
        // For custom mode
        this._proxyList = customList;
        this._listIdx = 0;

        // For auto/freeproxy mode pipeline
        this.verifiedQueue = [];   // ready-to-use verified proxies
        this.pendingQueue = [];   // fetched but not yet tested
        this.usedProxies = new Set(); // prevent reuse within a run
        this.totalFetched = 0;
        this.totalVerified = 0;
        this.totalFailed = 0;
        this.isRefilling = false;
        this.REFILL_TRIGGER = 50;   // start refill when queue drops below this
        this.TEST_CONCURRENCY = 20; // parallel connectivity tests
        this.DECODO_URL = 'https://scraper-api.decodo.com/v2/scrape';
        this.DECODO_AUTH = 'Basic VTAwMDAzNzI1MzY6UFdfMTMwMTAyMzU1MzkxYzdlZjM3YzMyZjY0ZTlmZTRlOWQ1';
        this._checkerRunning = false;
    }

    // ── Fetch all proxies from multiple sources (returns raw list, no filtering) ──
    async fetchFromDecodo() {
        try {
            log('🌐 Fetching proxies from multiple sources (Decodo + ProxyScrape + ProxyList)...');
            const https = require('https');
            const raw = [];
            
            // Helper for simple HTTPS GET requests
            const fetchGet = (url) => new Promise((resolve, reject) => {
                https.get(url, (res) => {
                    let body = '';
                    res.on('data', c => body += c);
                    res.on('end', () => resolve(body));
                }).on('error', reject);
            });

            // Source 1: Decodo API
            const decodoData = JSON.stringify({
                url: 'https://www.free-proxy-list.net/',
                proxy_pool: 'premium',
                headless: 'html'
            });
            const fetchDecodo = new Promise((resolve, reject) => {
                const req = https.request(this.DECODO_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(decodoData),
                        'Authorization': this.DECODO_AUTH
                    }
                }, (res) => {
                    let body = '';
                    res.on('data', c => body += c);
                    res.on('end', () => resolve(body));
                });
                req.on('error', reject);
                req.write(decodoData);
                req.end();
            });

            // Source 2: ProxyScrape API (using user API key)
            const fetchProxyScrape = fetchGet('https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=15000&country=all&ssl=all&anonymity=all&key=JFjQIW9goC1z7zGaWceXs3zwB1KkC0Mq61eTVNgn5oPB2s03M9JEn6TwfuvmYscM');

            // Source 3: Proxy-list.download API
            const fetchProxyList = fetchGet('https://www.proxy-list.download/api/v1/get?type=http');

            // Wait for all to finish
            const results = await Promise.allSettled([fetchDecodo, fetchProxyScrape, fetchProxyList]);
            
            // Combine all text returns into one giant string
            let combinedText = '';
            for (const r of results) {
                if (r.status === 'fulfilled' && typeof r.value === 'string') {
                    combinedText += '\n' + r.value;
                }
            }

            // Extract everything that looks like an IP:PORT
            const regex = /(\d+\.\d+\.\d+\.\d+):(\d+)/g;
            let m;
            while ((m = regex.exec(combinedText)) !== null) {
                raw.push({ ip: m[1], port: m[2] });
            }

            // De-duplicate
            const seen = new Set();
            const unique = raw.filter(p => {
                const k = `${p.ip}:${p.port}`;
                if (seen.has(k)) return false;
                seen.add(k); return true;
            });

            log(`📦 Scraped ${unique.length} unique proxies from all sources`);
            return unique;
        } catch (e) {
            log(`❌ Multi-fetch failed: ${e.message}`);
            return [];
        }
    }

    // ── Real HTTP CONNECT tunnel test ────────────────────────────────────────
    // Replaces the weak socket check with a strict '200 Connection established' tunnel test
    testTunnel(host, port, username, password, timeoutMs = 7000) {
        return new Promise((resolve) => {
            try {
                const authHeader = (username && password)
                    ? `Proxy-Authorization: Basic ${Buffer.from(`${username}:${password}`).toString('base64')}\r\n`
                    : '';
                const req = `CONNECT www.facebook.com:443 HTTP/1.1\r\nHost: www.facebook.com:443\r\n${authHeader}\r\n`;

                const sock = require('net').connect({ host, port: parseInt(port), timeout: timeoutMs });
                let responded = false;

                sock.setTimeout(timeoutMs, () => {
                    if (!responded) { responded = true; sock.destroy(); resolve(false); }
                });

                sock.on('connect', () => sock.write(req));

                sock.on('data', (chunk) => {
                    if (responded) return;
                    responded = true;
                    const resp = chunk.toString();
                    const ok = resp.includes('200');
                    // Silently test during background checks to avoid log spam, 
                    // debug logging disabled here since thousands are tested
                    sock.destroy();
                    resolve(ok);
                });

                sock.on('error', () => { if (!responded) { responded = true; resolve(false); } });
                sock.on('close', () => { if (!responded) { responded = true; resolve(false); } });
            } catch (e) {
                resolve(false);
            }
        });
    }

    // ── Background checker loop: picks from pendingQueue, tests concurrently ──
    async _startChecker() {
        if (this._checkerRunning) return;
        this._checkerRunning = true;

        while (true) {
            // If nothing to test, wait
            if (this.pendingQueue.length === 0) {
                await new Promise(r => setTimeout(r, 500));
                continue;
            }

            // Grab a batch to test concurrently
            const batch = this.pendingQueue.splice(0, this.TEST_CONCURRENCY);
            const results = await Promise.all(
                batch.map(async (p) => {
                    const ok = await this.testTunnel(p.ip, p.port, '', '', 5000);
                    return { p, ok };
                })
            );

            for (const { p, ok } of results) {
                if (ok) {
                    this.verifiedQueue.push(`${p.ip}:${p.port}`);
                    this.totalVerified++;
                } else {
                    this.totalFailed++;
                }
            }

            // Trigger refill if queue is low and checker has exhausted pending list
            if (!this.isRefilling && this.pendingQueue.length === 0 && this.verifiedQueue.length < this.REFILL_TRIGGER) {
                this._refill(); // fire-and-forget
            }

            await new Promise(r => setTimeout(r, 10));
        }
    }

    // ── Fetch a new batch from APIs and add to pending queue ──
    async _refill() {
        if (this.isRefilling) return;
        this.isRefilling = true;
        log('🔄 Refilling auto proxy pool...');
        try {
            const fresh = await this.fetchFromDecodo();
            // Filter out already-used proxies
            const novel = fresh.filter(p => !this.usedProxies.has(`${p.ip}:${p.port}`));
            this.pendingQueue.push(...novel);
            this.totalFetched += novel.length;
            log(`📥 Added ${novel.length} new proxies to pending queue (${this.pendingQueue.length} pending, ${this.verifiedQueue.length} verified)`);
        } catch (e) {
            log(`❌ Refill failed: ${e.message}`);
        }
        this.isRefilling = false;
    }

    // ── Start the system ──────────────────────────────────────────────────
    async start() {
        if (this.mode === 'freeproxy') {
            log('🚀 Starting Auto-Scraping ProxyManager pipeline (Enhanced)...');
            const initial = await this.fetchFromDecodo();
            this.pendingQueue.push(...initial);
            this.totalFetched = initial.length;
            log(`📋 ${initial.length} scraped proxies queued. Starting robust TCP tunneling verifier...`);

            // Start checker in background (runs forever)
            this._startChecker();

            // Wait until at least 15 verified proxies are ready before starting OTP work
            log('⏳ Waiting up to 30s for the first 15 fully-verified proxies...');
            const waitStart = Date.now();
            while (this.verifiedQueue.length < 15 && Date.now() - waitStart < 30000) {
                await new Promise(r => setTimeout(r, 300));
            }
            if (this.verifiedQueue.length === 0) {
                log('⚠️ No proxies passed the strict tunnel verification in 30s. Falling back to direct connection.');
                this.mode = 'direct';
            } else {
                log(`✅ ProxyManager ready: ${this.verifiedQueue.length} ultra-verified proxies in queue!`);
            }
        } 
        else if (this.mode === 'custom') {
            log(`📋 Custom proxy list: ${this._proxyList.length} proxies. Checking connectivity...`);
            let alive = 0;
            const checked = [];
            for (const p of this._proxyList) {
                const parts = p.split(':');
                const [host, port, user, pass] = parts.length >= 4 
                    ? parts : [parts[0], parts[1], '', ''];
                const ok = await this.testTunnel(host, port, user, pass, 6000);
                if (ok) { alive++; checked.push(p); }
                else this.totalFailed++;
            }
            this._proxyList = checked;
            this.totalVerified = alive;
            log(`✅ Custom proxies: ${alive}/${alive + this.totalFailed} verified and ready.`);
        } 
        else {
            log('🚀 Direct mode — no proxy');
        }
    }

    getProxy() {
        if (this.mode === 'custom') {
            if (this._proxyList.length === 0) return null;
            const proxy = this._proxyList[this._listIdx % this._proxyList.length];
            this._listIdx++;
            this.usedProxies.add(proxy);
            return proxy;
        } 
        else if (this.mode === 'freeproxy') {
            if (this.verifiedQueue.length === 0) return null;
            const proxy = this.verifiedQueue.shift(); // pop from front (FIFO)
            this.usedProxies.add(proxy);

            // Trigger background refill only when pending list is also exhausted
            if (this.verifiedQueue.length < this.REFILL_TRIGGER && !this.isRefilling && this.pendingQueue.length === 0) {
                this._refill(); // fire-and-forget
            }
            return proxy;
        }
        return null; // direct
    }

    get totalVerifiedDisplay() {
        return this.mode === 'freeproxy' ? this.verifiedQueue.length : (this._proxyList ? this._proxyList.length : 0);
    }

    markSuccess(proxy) { }
    markFailure(proxy) {
        if (proxy && this.mode === 'custom') {
            const idx = this._proxyList.indexOf(proxy);
            if (idx !== -1) this._proxyList.splice(idx, 1);
            this.totalFailed++;
        } else if (proxy && this.mode === 'freeproxy') {
            this.usedProxies.add(proxy);
            const idx = this.verifiedQueue.indexOf(proxy);
            if (idx !== -1) this.verifiedQueue.splice(idx, 1);
        }
    }

    getStats() {
        if (this.mode === 'freeproxy') {
            return {
                verified: this.verifiedQueue.length,
                pending: this.pendingQueue.length,
                totalFetched: this.totalFetched,
                totalVerified: this.totalVerified,
                totalFailed: this.totalFailed,
                used: this.usedProxies.size,
                mode: this.mode
            };
        } else {
            return {
                verified: this._proxyList ? this._proxyList.length : 0,
                pending: 0,
                totalFetched: this._proxyList ? this._proxyList.length : 0,
                totalVerified: this.totalVerified,
                totalFailed: this.totalFailed,
                used: this.usedProxies ? this.usedProxies.size : 0,
                mode: this.mode
            };
        }
    }
}




// ── Proxy helper functions (wrappers around ProxyManager) ────────
let currentLanguage = 'en';

function getHealthyProxy(language = 'en') {
    if (!proxyManager) return null;
    const proxy = proxyManager.getProxy();
    if (proxy) {
        const s = proxyManager.getStats();
        debug(`🌐 Proxy assigned: ${proxy} | verified queue: ${s.verified} | pending: ${s.pending}`);
    } else {
        debug('⚠️ No verified proxy available — using direct connection');
    }
    return proxy || null;
}

function markProxySuccess(proxyString) {
    if (proxyManager && proxyString) proxyManager.markSuccess(proxyString);
}

function markProxyFailure(proxyString) {
    if (proxyManager && proxyString) proxyManager.markFailure(proxyString);
}

function resetProxyDistribution() {
    debug('🔄 Proxy distribution reset (no-op in pipeline mode)');
}

function updateProxyStats(proxy, success, errorMsg = null) {
    if (!proxy) return;
    if (success) markProxySuccess(proxy);
    else markProxyFailure(proxy);
}


function log(msg) {
    const line = `[${new Date().toISOString()}] ${msg}`;
    try {
        fs.appendFileSync(LOG_FILE, line + '\n');
    } catch (e) {
        console.error('Failed to write log:', e.message);
    }
    addLog(line);
}

function debug(msg) {
    try {
        fs.appendFileSync(DEBUG_FILE, `[${new Date().toISOString()}] ${msg}\n`);
    } catch (e) {
        console.error('Failed to write debug:', e.message);
    }
}

function saveNumber(file, number) {
    try {
        fs.appendFileSync(file, number + '\n');
    } catch (e) {
        console.error(`Failed to save to ${file}:`, e.message);
    }
}

function printFinalResult(elapsed) {
    const pct = stats.total > 0 ? Math.round((stats.success / stats.total) * 100) : 0;
    const w = W();
    const sep = '═'.repeat(w - 2);
    console.log(`\x1b[36m╔${sep}╗\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m${pad('  FINAL RESULTS  (' + elapsed + 's)', w - 2)}\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m╠${sep}╣\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[37m📊 Total        : ${pad(stats.total, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[32m✅ OTP sent     : ${pad(stats.success, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[31m⛔ No account   : ${pad(stats.noAccount, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[33m⚠️  No SMS       : ${pad(stats.noSms, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[31m❌ Errors       : ${pad(stats.errors, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[35m🚫 Rate limited : ${pad(stats.rateLimited, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[33m🤖 Captcha      : ${pad(stats.captcha, w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m║\x1b[0m  \x1b[35m📈 Success rate : ${pad(pct + '%', w - 22)}\x1b[0m\x1b[36m║\x1b[0m`);
    console.log(`\x1b[36m╚${sep}╝\x1b[0m\n`);
    process.stdout.write(`\x1b]0;DONE ✅${stats.success} ⛔${stats.noAccount} ❌${stats.errors} Rate:${pct}%\x07`);
}

// ── Feature 5: Save/load progress ────────────────────────────
function saveProgress(currentIndex, numbers) {
    try {
        const processedCount = numbers.slice(0, currentIndex).filter(n => processedNumbers.has(n)).length;
        const data = {
            savedAt: new Date().toISOString(),
            currentIndex: processedCount,
            processedNumbers: [...processedNumbers],
            stats,
        };
        fs.writeFileSync(PROGRESS_FILE, JSON.stringify(data, null, 2));
    } catch (e) {
        console.error('Failed to save progress:', e.message);
    }
}

function loadProgress() {
    try {
        if (fs.existsSync(PROGRESS_FILE)) {
            const data = JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
            return data;
        }
    } catch (e) { }
    return null;
}

function clearProgress() {
    try { if (fs.existsSync(PROGRESS_FILE)) fs.unlinkSync(PROGRESS_FILE); } catch (e) { }
}

// ── Proxy checker ─────────────────────────────────────────────
function checkProxy(proxyStr, timeout = 6000) {
    return new Promise((resolve) => {
        try {
            proxyStr = proxyStr.trim();
            let host, port, username, password;
            if (proxyStr.includes('@')) {
                const [creds, hp] = proxyStr.split('@');
                [username, password] = creds.split(':');
                [host, port] = hp.split(':');
            } else {
                const parts = proxyStr.split(':');
                if (parts.length === 4) [host, port, username, password] = parts;
                else if (parts.length === 2) [host, port] = parts;
                else return resolve(false);
            }
            const opts = { host, port: parseInt(port), method: 'CONNECT', path: 'www.facebook.com:443', timeout };
            if (username) opts.auth = `${username}:${password}`;
            const req = http.request(opts);
            req.setTimeout(timeout, () => { req.destroy(); resolve(false); });
            req.on('connect', () => { req.destroy(); resolve(true); });
            req.on('error', () => resolve(false));
            req.end();
        } catch (e) { resolve(false); }
    });
}

async function checkAllProxies(proxies, silent = false) {
    if (!silent) {
        process.stdout.write(`\n  Checking ${proxies.length} proxies...\n`);
    }
    let alive = 0, dead = 0;
    const BATCH_SIZE = 10; // Limit concurrent checks
    const results = [];

    for (let i = 0; i < proxies.length; i += BATCH_SIZE) {
        const batch = proxies.slice(i, i + BATCH_SIZE);
        const batchResults = await Promise.all(
            batch.map(async (proxy) => {
                const ok = await checkProxy(proxy);
                if (ok) alive++; else dead++;
                if (!silent) {
                    process.stdout.write(`\r  \x1b[32m✅ Alive: ${alive}\x1b[0m   \x1b[31m❌ Dead: ${dead}\x1b[0m   Checked: ${alive + dead}/${proxies.length}   `);
                }
                return { proxy, alive: ok };
            })
        );
        results.push(...batchResults);

        // Small delay between batches to avoid overwhelming network
        if (i + BATCH_SIZE < proxies.length) {
            await new Promise(r => setTimeout(r, 100));
        }
    }

    if (!silent) process.stdout.write('\n\n');
    return results.filter(r => r.alive).map(r => r.proxy);
}

// ── Feature 2: Smart retry on different domain ────────────────
function getDomainForRetry(lastDomain, attempt, FB_DOMAINS) {
    const idx = FB_DOMAINS.indexOf(lastDomain);
    // Pick a different domain each retry attempt
    return FB_DOMAINS[(idx + attempt + 1) % FB_DOMAINS.length];
}

// ── Feature 6: Rate limit pause ───────────────────────────────
async function handleRateLimit() {
    rateLimitPause = true;
    stats.rateLimited++;
    log(`🚫 Rate limited! Pausing all workers for ${RATELIMIT_PAUSE_MS / 1000}s...`);
    await new Promise(r => setTimeout(r, RATELIMIT_PAUSE_MS));
    rateLimitPause = false;
    consecutiveErrors = 0;
    log(`▶️  Resuming after rate limit pause`);
}

async function main() {
    clearScreen();
    console.log(line());
    console.log('  FB Recovery OTP Autofill — Full Enhanced\n');
    console.log(line());

    const args = process.argv.slice(2);
    if (args.length < 1) {
        console.log('  Usage: node autofill.js numbers.txt [proxy.txt] [workers] [ua.txt] [language]\n');
        process.exit(1);
    }

    const inputFile = args[0];
    const proxyFile = args[1];
    const requestedWorkersArg = args[2];
    let numWorkers;
    const cpuThreads = os.cpus().length;
    const reservedRam = 2 * 1024 * 1024 * 1024; // 2GB for OS
    const availableMem = Math.max(0, os.totalmem() - reservedRam);
    const maxWorkersByRam = Math.floor(availableMem / (350 * 1024 * 1024)); // 350MB per worker
    const maxSafeWorkers = Math.max(1, Math.min(30, Math.min(cpuThreads * 2, maxWorkersByRam)));

    if (requestedWorkersArg) {
        const req = parseInt(requestedWorkersArg);
        if (req > maxSafeWorkers) {
            console.log(`\x1b[33m⚠️  Warning: Requested ${req} workers, but hardware safely supports ~${maxSafeWorkers}.\x1b[0m`);
            numWorkers = Math.min(req, 100); // hard cap at 100 to prevent system crash
        } else {
            numWorkers = req;
        }
    } else {
        // Feature: Auto detect hardware configuration to set limits
        numWorkers = maxSafeWorkers;
        console.log(`\x1b[36m💻 Auto-detected optimal workers: ${numWorkers} (${Math.round(availableMem/1024/1024/1024)}GB Free RAM, ${cpuThreads} CPUs)\x1b[0m`);
    }
    const languageCodes = args[3] || 'en'; // Can be single or comma-separated
    const proxyChoice = args[4] || 'auto'; // auto, custom, direct

    console.log(`🔧 Proxy Mode: ${proxyChoice.toUpperCase()}`);

    // Parse language codes (handle single or multiple)
    const languageList = languageCodes.split(',').map(lang => lang.trim()).filter(Boolean);
    console.log(`🌍 Using ${languageList.length} language(s): ${languageList.join(', ').toUpperCase()}`);

    // ── Auto-detect proxy mode ──
    let resolvedMode = proxyChoice;
    if (resolvedMode === 'auto') {
        if (proxyFile && fs.existsSync(proxyFile)) {
            resolvedMode = 'custom';
            console.log(`📁 Auto-detected proxy file — using custom mode: ${proxyFile}`);
        } else {
            resolvedMode = 'freeproxy';
            console.log('🌍 No proxy file found — auto-fetching free proxies from the internet');
        }
    }

    console.log(`🔧 Proxy Mode: ${resolvedMode.toUpperCase()}`);

    // Initialize proxy system based on resolved mode
    if (resolvedMode === 'freeproxy') {
        console.log(`🌐 Free Proxy Auto-Scraper mode`);
        console.log('   ✦ Automatically fetching thousands of public HTTP proxies...');
        console.log('   ✦ Checking them against Facebook to drop dead ones');
        proxyManager = new ProxyManager('freeproxy');
        await proxyManager.start();
    } else if (resolvedMode === 'custom' && proxyFile && fs.existsSync(proxyFile)) {
        console.log(`📁 Loading custom proxy file: ${proxyFile}`);
        try {
            const lines = fs.readFileSync(proxyFile, 'utf8')
                .split('\n')
                .map(l => l.trim())
                .filter(l => l && l.includes(':'));
            proxyManager = new ProxyManager('custom', lines);
            await proxyManager.start();
        } catch (error) {
            console.log(`❌ Failed to load custom proxy file: ${error.message}`);
            console.log('⚠️ Falling back to direct connection');
            proxyManager = null;
        }
    } else {
        console.log('🚀 Using direct connection (no proxies)');
        proxyManager = new ProxyManager('direct');
    }

    // Direct mode IP protections
    if (proxyManager && proxyManager.mode === 'direct' && numWorkers > 2) {
        console.log(`\n\x1b[33m⚠️  Throttling workers from ${numWorkers} to 2 to prevent IP ban/rate-limiting on direct connection.\x1b[0m\n`);
        numWorkers = 2;
    }

    // Auto-generate fresh user agents for this run
    const userAgents = generateFreshUserAgents();
    const totalUA = userAgents.mobile.length + userAgents.desktop.length;
    console.log(`🔄 Generated ${totalUA} fresh user agents`);
    console.log(`📱 Mobile-first: ${Math.round((userAgents.mobile.length / totalUA) * 100)}%`);

    // Setup output directory
    const dir = path.join(inputFile, '..', 'results');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    SUCCESSFUL_FILE = path.join(dir, 'successful.txt');
    FAILED_FILE = path.join(dir, 'failed.txt');
    LOG_FILE = path.join(dir, 'log.txt');
    DEBUG_FILE = path.join(dir, 'debug.txt');
    PROGRESS_FILE = path.join(dir, 'progress.json');
    NO_SMS_FILE = path.join(dir, 'no_sms.txt');

    if (!fs.existsSync(inputFile)) { console.error(`\n  File not found: ${inputFile}\n`); process.exit(1); }

    console.log('\n🔌 Using Proxy Only mode (VPN removed for reliability)');
    console.log('💡 This version is simpler and more reliable');
    console.log(`🌍 Using ${languageList.length} language(s): ${languageList.join(', ').toUpperCase()}\n`);
    console.log('⏳ Warming up... waiting 15 seconds before starting\n');

    // Initial warm-up delay to avoid immediate rate limiting
    await new Promise(r => setTimeout(r, 15000));

    if (inputFile.endsWith('.bat') || inputFile.endsWith('.js')) {
        console.error(`\n  ❌ ERROR: Do not use script files (${inputFile}) as the numbers list!\n`);
        process.exit(1);
    }
    
    let allNumbers = fs.readFileSync(inputFile, 'utf8').split('\n').map(n => n.trim()).filter(Boolean);
    // Strict Input Validation: reject any lines containing letters, preventing code files from being parsed
    const phoneRegex = /^[+]?[1-9]\d{1,14}$/;
    allNumbers = allNumbers.filter(n => {
        if (/[a-zA-Z]/.test(n)) return false; 
        return phoneRegex.test(n.replace(/[^\d+]/g, ''));
    });
    // Clean numbers
    allNumbers = allNumbers.map(n => n.replace(/[^\d+]/g, ''));
    allNumbers = [...new Set(allNumbers)];

    // Feature: Shuffle numbers array so we process a random distribution
    // This perfectly handles IVR lists that have blocks of active/inactive numbers
    allNumbers.sort(() => Math.random() - 0.5);

    if (allNumbers.length === 0) {
        console.error('\n  No valid phone numbers found in the input file!\n');
        process.exit(1);
    }

    let allProxies = [];

    // With ProxyManager, we don't use allProxies array anymore — proxies are pulled per-task.
    // Show info based on proxyManager state.
    if (proxyManager) {
        const s = proxyManager.getStats();
        allProxies = Array(s.verified + s.pending).fill('pipeline'); // fake count for display only
        console.log(`🚀 ProxyManager active: ${s.verified} verified ready, ${s.pending} being tested`);
    } else if (proxyFile && proxyFile.trim() !== '' && fs.existsSync(proxyFile)) {
        allProxies = fs.readFileSync(proxyFile, 'utf8').split('\n').map(p => p.trim()).filter(Boolean);
        console.log(`📁 Using ${allProxies.length} proxies from file: ${proxyFile}`);
    }

    const workerFile = path.join(__dirname, 'worker.js');
    if (!fs.existsSync(workerFile)) { console.error('\n  worker.js not found!\n'); process.exit(1); }

    // ── Feature 5: Check for previous progress ────────────────
    let startIndex = 0;
    const saved = loadProgress();
    if (saved) {
        clearScreen();
        console.log('\n  ⚡ Previous run found!\n');
        console.log(`  Saved at  : ${saved.savedAt}`);
        console.log(`  Progress  : ${saved.currentIndex}/${allNumbers.length}`);
        console.log(`  OTP sent  : ${saved.stats.success}`);
        console.log('\n  R = Resume from where you left off');
        console.log('  N = Start fresh\n');
        const answer = await new Promise(resolve => {
            process.stdout.write('  Your choice (R/N): ');
            process.stdin.setEncoding('utf8');
            process.stdin.resume();
            process.stdin.once('data', d => {
                process.stdin.pause();
                resolve(d.trim().toUpperCase());
            });
        });
        if (answer === 'R') {
            startIndex = saved.currentIndex || 0;
            processedNumbers = new Set(saved.processedNumbers || []);
            stats = { ...stats, ...saved.stats };
            console.log(`\n  ▶️  Resuming from number ${startIndex}...\n`);
            await new Promise(r => setTimeout(r, 1000));
        } else {
            clearProgress();
            console.log('\n  🔄 Starting fresh...\n');
            await new Promise(r => setTimeout(r, 1000));
        }
    }

    // Filter out already processed numbers
    const numbers = allNumbers.slice(startIndex).filter(n => !processedNumbers.has(n));

    clearScreen();
    console.log('');
    console.log(`\x1b[36m${line('═')}\x1b[0m`);
    console.log(`\x1b[36m  FB Recovery OTP Autofill — Full Featured\x1b[0m`);
    console.log(`\x1b[36m${line('═')}\x1b[0m`);
    console.log(`  Numbers  : \x1b[32m${numbers.length}\x1b[0m${startIndex > 0 ? ` \x1b[33m(resuming from ${startIndex})\x1b[0m` : ''}`);
    const proxyDisplay = proxyManager
        ? `pipeline (${proxyManager.getStats().verified} verified)`
        : (allProxies.length > 0 ? `${allProxies.length} from file` : 'none (direct)');
    console.log(`  Proxies  : \x1b[33m${proxyDisplay}\x1b[0m`);
    console.log(`  Workers  : \x1b[35m${numWorkers}\x1b[0m`);
    console.log(`  Agents   : \x1b[35m${totalUA}\x1b[0m`);
    console.log(`\x1b[36m${line('\u2500')}\x1b[0m\n`);

    // ProxyManager handles proxy assignment per-task via getHealthyProxy().
    // Legacy file-proxy testing only runs if no proxyManager and proxies came from file.
    if (!proxyManager && allProxies.length > 0) {
        console.log(`  🔍 Testing proxies from file...\n`);
        const liveFromFile = await checkAllProxies(allProxies);
        if (liveFromFile.length === 0) {
            console.log('  ⚠️  No alive proxies! Running without proxy.\n');
            allProxies = [];
        } else {
            allProxies = liveFromFile;
            console.log(`  🚀 Using \x1b[32m${allProxies.length}\x1b[0m alive proxies\n`);
        }
    }

    if (!numbers.length) {
        console.log('  ✅ All numbers already processed!\n');
        clearProgress();
        process.exit(0);
    }

    stats.total = allNumbers.length;
    updateTitle();
    console.log('');
    processingStarted = true;
    drawDashboard();

    // Reset proxy distribution for new batch
    resetProxyDistribution();

    // ── Worker pool ───────────────────────────────────────────
    const startTime = Date.now(); // track for finishUp
    let currentIndex = 0;
    let completedWorkers = 0;
    let retryQueue = [];
    let numberAttempts = {};
    let numberDomains = {}; // track last domain used per number
    let numberProxies = {}; // track proxy used per number
    const workers = [];
    let saveTimer = null;
    const terminatedWorkers = new Set();

    const scheduleSave = () => {
        if (saveTimer) clearTimeout(saveTimer);
        saveTimer = setTimeout(() => {
            saveProgress(startIndex + currentIndex, allNumbers);
            // Rewrite the input file, removing used numbers
            try {
                const remaining = allNumbers.filter(n => !processedNumbers.has(n));
                fs.writeFileSync(inputFile, remaining.join('\n') + (remaining.length ? '\n' : ''));
            } catch (e) {
                debug(`Failed to remove used numbers from input file: ${e.message}`);
            }
        }, 2000);
    };

    const getNextTask = () => {
        if (retryQueue.length > 0) return retryQueue.shift();
        if (currentIndex >= allNumbers.length) return null;
        const number = allNumbers[currentIndex++];
        if (processedNumbers.has(number)) return getNextTask();

        // Distribute languages across workers for multi-language strategy
        let languageIndex = undefined;
        if (languageList.length > 1) {
            // Round-robin language distribution
            languageIndex = (currentIndex - 1) % languageList.length;
            debug(`🌍 Assigning language ${languageList[languageIndex].toUpperCase()} to ${number} (index ${languageIndex})`);
        }

        return { number, languageIndex };
    };

    return new Promise((resolve) => {
        const sendTask = (worker, task, workerId) => {
            // Feature 4: Handle language rotation and selection
            let currentLanguage = languageList[0]; // Default to first language

            if (task.languageRotation && task.newLanguage) {
                currentLanguage = task.newLanguage;
                debug(`🌍 Using rotated language ${currentLanguage} for ${task.number}`);
            } else if (task.languageIndex !== undefined) {
                // Use specific language from the list
                currentLanguage = languageList[task.languageIndex % languageList.length];
                debug(`🌍 Using language ${currentLanguage.toUpperCase()} (index ${task.languageIndex}) for ${task.number}`);
            } else if (languageList.length > 1) {
                // Fallback: use worker ID to distribute languages
                currentLanguage = languageList[workerId % languageList.length];
                debug(`🌍 Using fallback language ${currentLanguage.toUpperCase()} (worker ${workerId}) for ${task.number}`);
            }

            // Get proxy for this specific language
            const proxy = getHealthyProxy(currentLanguage);

            // Get domains for current language
            const currentDomains = FB_DOMAINS_BY_LANGUAGE[currentLanguage] || FB_DOMAINS_BY_LANGUAGE['en'];

            // Feature 2: use different domain for retries
            const domainIndex = task.retryAttempt
                ? currentDomains.indexOf(numberDomains[task.number] || currentDomains[0])
                : (task.domainIndex !== undefined ? task.domainIndex : workerId % currentDomains.length);

            const domain = task.retryAttempt
                ? getDomainForRetry(numberDomains[task.number] || currentDomains[0] || 'https://www.facebook.com', task.retryAttempt, currentDomains)
                : currentDomains[domainIndex % currentDomains.length] || 'https://www.facebook.com';

            numberDomains[task.number] = domain;

            // Intelligently select a User-Agent that matches the assigned domain type
            const isMobileDomain = domain.includes('m.') || domain.includes('mbasic.') || domain.includes('touch.') || domain.includes('free.');
            const uaList = isMobileDomain ? userAgents.mobile : userAgents.desktop;
            const ua = uaList[Math.floor(Math.random() * uaList.length)];

            debug(`Worker ${workerId} assigned proxy: ${proxy || 'direct'} for ${task.number} (Lang: ${currentLanguage.toUpperCase()}, Mode: Proxy Only)`);
            numberProxies[task.number] = proxy; // track which proxy was used
            worker.postMessage({ number: task.number, proxy, domain, userAgent: ua, language: currentLanguage });
        };

        const createWorker = (id) => {
            try {
                const worker = new Worker(workerFile);
                workers[id] = worker;

                worker.on('message', async (msg) => {
                    // Handle proxy tracking messages
                    if (msg.type === 'proxy_success') {
                        markProxySuccess(msg.proxy);
                        return;
                    }

                    if (msg.type === 'proxy_failure') {
                        if (proxyManager) proxyManager.markFailure(msg.proxy);
                        return;
                    }

                    if (msg.type === 'debug') {
                        debug(msg.message);
                        return;
                    }

                    if (msg.type !== 'result') return;
                    const { number, result, errorMsg, language, proxy: usedProxy, sendCount } = msg;

                    // Immediately blacklist any proxy that failed during navigation
                    if (result === 'error' && usedProxy && proxyManager) {
                        proxyManager.markFailure(usedProxy);
                    }

                    // Feature 6: Enhanced rate limit detection
                    if (errorMsg && RATELIMIT_SIGNALS.some(signal =>
                        errorMsg.toLowerCase().includes(signal) ||
                        errorMsg.toLowerCase().includes('rate') ||
                        errorMsg.toLowerCase().includes('limit') ||
                        errorMsg.toLowerCase().includes('block')
                    )) {
                        debug(`Rate limit detected: ${errorMsg}`);
                        await handleRateLimit();
                    }

                    // Feature 7: captcha detection
                    if (result === 'captcha') {
                        stats.captcha++;
                        stats.done++;
                        processedNumbers.add(number);
                        log(`🤖 [${stats.done}/${stats.total}] ${number}  →  Captcha detected — skipping`);
                        scheduleSave();
                        const next = getNextTask();
                        if (next) sendTask(worker, next, id);
                        else {
                            completedWorkers++;
                            if (!terminatedWorkers.has(id)) {
                                terminatedWorkers.add(id);
                                try { worker.terminate(); } catch (_) { }
                            }
                            if (completedWorkers >= numWorkers) finishUp(resolve, startTime);
                        }
                        return;
                    }

                    if (result === 'success') {
                        stats.success++;
                        stats.done++;
                        consecutiveErrors = 0;
                        processedNumbers.add(number);
                        saveNumber(SUCCESSFUL_FILE, number);
                        updateProxyStats(numberProxies[number] || null, true);

                        // Track successful OTP sent
                        const sends = sendCount > 1 ? ` x${sendCount}` : '';
                        log(`✅ [${stats.done}/${stats.total}] ${number}  →  OTP sent${sends}  [${language?.toUpperCase() || 'EN'}] [${numberDomains[number]?.replace('https://', '') || ''}]`);

                    } else if (result === 'no_account') {
                        stats.noAccount++;
                        stats.done++;
                        consecutiveErrors = 0; // successful response, not an error
                        processedNumbers.add(number);
                        saveNumber(FAILED_FILE, number);
                        updateProxyStats(numberProxies[number] || null, true);
                        log(`⛔ [${stats.done}/${stats.total}] ${number}  →  No account`);
                    } else if (result === 'no_sms') {
                        stats.noSms++;
                        stats.done++;
                        consecutiveErrors = 0; // successful response, not an error
                        processedNumbers.add(number);
                        saveNumber(NO_SMS_FILE, number);
                        updateProxyStats(numberProxies[number] || null, true);
                        log(`⚠️  [${stats.done}/${stats.total}] ${number}  →  No SMS option`);
                    } else if (errorMsg && errorMsg.startsWith('Proxy failure:')) {
                        // Proxy failed — dead IP already blacklisted above, retry immediately with new proxy
                        updateProxyStats(numberProxies[number] || null, false, errorMsg);
                        // Short 2s delay before retry to avoid stampede, then use a fresh proxy
                        setTimeout(() => {
                            retryQueue.push({ number, retryAttempt: numberAttempts[number] || 0 });
                        }, 2000);
                    } else {
                        // Error — Feature 2: retry on different domain with smart delays
                        const attempts = (numberAttempts[number] || 0) + 1;
                        numberAttempts[number] = attempts;
                        consecutiveErrors++;
                        updateProxyStats(numberProxies[number] || null, false, errorMsg);

                        if (attempts < MAX_RETRY_ATTEMPTS) {
                            const delay = RETRY_DELAYS[attempts - 1] || RETRY_DELAYS[RETRY_DELAYS.length - 1];
                            debug(`${number} attempt ${attempts} - ${errorMsg} - retrying in ${delay}ms`);
                            log(`🔄 [${stats.done}/${stats.total}] ${number}  →  Retry ${attempts}/${MAX_RETRY_ATTEMPTS} in ${delay / 1000}s`);

                            // Add delay before retry
                            setTimeout(() => {
                                retryQueue.push({ number, retryAttempt: attempts });
                            }, delay);
                        } else {
                            stats.errors++;
                            stats.done++;
                            processedNumbers.add(number);
                            log(`❌ [${stats.done}/${stats.total}] ${number}  →  Failed after ${MAX_RETRY_ATTEMPTS} attempts`);
                        }

                        // Feature 6: too many consecutive errors = rate limited
                        if (consecutiveErrors >= 10) {
                            await handleRateLimit();
                        }
                    }

                    scheduleSave();

                    // Update dashboard
                    updateTitle();
                    drawDashboard();

                    // Rate limit pause — wait before sending next task
                    if (rateLimitPause) {
                        await new Promise(r => setTimeout(r, RATELIMIT_PAUSE_MS));
                    }

                    const next = getNextTask();
                    if (next) {
                        sendTask(worker, next, id);
                    } else {
                        completedWorkers++;
                        if (!terminatedWorkers.has(id)) {
                            terminatedWorkers.add(id);
                            try { worker.terminate(); } catch (_) { }
                        }
                        if (completedWorkers >= numWorkers) finishUp(resolve, startTime);
                    }
                });

                worker.on('error', (err) => {
                    debug(`Worker ${id} crash: ${err.message}`);
                    completedWorkers++;
                    if (!terminatedWorkers.has(id)) {
                        terminatedWorkers.add(id);
                        try { worker.terminate(); } catch (_) { }
                    }
                    if (completedWorkers >= numWorkers) finishUp(resolve, startTime);
                });

            } catch (e) {
                log(`Failed worker ${id}: ${e.message}`);
                completedWorkers++;
                if (!terminatedWorkers.has(id)) {
                    terminatedWorkers.add(id);
                }
                if (completedWorkers >= numWorkers) finishUp(resolve, startTime);
            }
        };

        for (let i = 0; i < numWorkers; i++) createWorker(i);

        for (let i = 0; i < numWorkers; i++) {
            setTimeout(() => {
                if (!workers[i] || terminatedWorkers.has(i)) return;
                const task = getNextTask();
                if (task) {
                    // Add much longer random delay before starting each worker
                    setTimeout(() => {
                        sendTask(workers[i], task, i);
                    }, Math.random() * 15000 + 10000); // 10-25 seconds random delay
                } else {
                    completedWorkers++;
                    if (completedWorkers >= numWorkers) finishUp(resolve, startTime);
                }
            }, i * 20000); // 20 seconds between worker starts (much slower)
        }

        // No artificial timeout - let system finish naturally
        // System will stop when all numbers are processed
    });
}

function finishUp(resolve, startTime) {
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    try {
        fs.appendFileSync(LOG_FILE, `[${new Date().toISOString()}] === DONE in ${elapsed}s ===\n`);
    } catch (e) {
        console.error('Failed to write final log:', e.message);
    }
    clearProgress();
    printFinalResult(elapsed);
    resolve();
}

main().catch(err => {
    console.error('Fatal:', err.message);
    process.exit(1);
});

process.on('SIGINT', () => {
    saveProgress(0, []);
    printFinalResult('interrupted');
    process.exit(0);
});
