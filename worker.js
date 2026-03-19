// ============================================================
//  Worker — One persistent browser, clears session per number
// ============================================================

const { parentPort } = require('worker_threads');

let chromium, StealthPlugin;
let browser = null;

async function loadPlaywright() {
    if (!chromium) {
        const pw = require('playwright-extra');
        const sp = require('puppeteer-extra-plugin-stealth');
        chromium = pw.chromium;
        StealthPlugin = sp;
        chromium.use(StealthPlugin());
    }
}

async function getBrowser() {
    // Launch once, reuse for all numbers in this worker. Proxy is applied per-context now.
    if (!browser || !browser.isConnected()) {
        const opts = {
            headless: true,
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-gpu',
                '--no-zygote',
                '--disable-extensions',
                '--disable-background-networking',
                '--disable-sync',
                '--disable-translate',
                '--hide-scrollbars',
                '--metrics-recording-only',
                '--mute-audio',
                '--no-first-run',
                '--safebrowsing-disable-auto-update',
                '--disable-web-security',
                '--disable-features=VizDisplayCompositor',
                '--disable-blink-features=AutomationControlled',
                '--disable-ipc-flooding-protection',
            ],
        };
        try {
            debug('Launching new browser instance...');
            browser = await chromium.launch(opts);
            debug('Browser launched successfully');
        } catch (e) {
            debug(`Browser launch failed: ${e.message}`);
        }
    }
    return browser;
}

const sleep = ms => new Promise(r => setTimeout(r, ms));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1) + min);

function debug(msg) {
    try {
        require('fs').appendFileSync('debug.txt', `[${new Date().toISOString()}] ${msg}\n`);
    } catch (e) { }
}

function parseProxy(proxyStr) {
    if (!proxyStr) return null;
    proxyStr = proxyStr.trim();
    if (!proxyStr.includes(':')) return null;
    try {
        if (proxyStr.includes('@')) {
            const [creds, hp] = proxyStr.split('@');
            if (!creds || !hp) return null;
            const [username, password] = creds.split(':');
            const [host, port] = hp.split(':');
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `http://${host}:${port}`, username, password: password || '' };
        }
        const parts = proxyStr.split(':');
        if (parts.length === 4) {
            const [host, port, username, password] = parts;
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `http://${host}:${port}`, username, password: password || '' };
        }
        if (parts.length === 3) {
            const [host, port, username] = parts;
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `http://${host}:${port}`, username, password: '' };
        }
        if (parts.length === 2) {
            const [host, port] = parts;
            if (!host || !port) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `http://${host}:${port}` };
        }
    } catch (e) {
        return null;
    }
    return null;
}

// ── Dynamic UA Generator ─────────────────────────────────────────────────────
// Generates a completely fresh user agent for every single task,
// properly matched to whether the target domain is mobile or desktop.
function generateUA(isMobile) {
    const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];

    const androidDevices = [
        'SM-G998B', 'SM-S918B', 'SM-G991B', 'SM-A546B', 'SM-A736B', 'SM-G990B',
        'Pixel 8 Pro', 'Pixel 8', 'Pixel 7 Pro', 'Pixel 7', 'Pixel 6 Pro', 'Pixel 6',
        'Pixel 5', 'Pixel 4a', 'CPH2387', 'IN2020', 'LE2123', 'RMX3761', 'V2111',
    ];
    const androidVersions = ['14', '13', '12', '11', '10'];
    const chromeVersions = [
        '125.0.6422.113', '124.0.6367.82', '123.0.6312.105',
        '122.0.6261.119', '121.0.6167.140', '120.0.6099.230',
        '119.0.6045.194', '118.0.5993.111',
    ];

    const iOSVersions = [
        '17_4_1', '17_4', '17_3_1', '17_3', '17_2_1', '17_2',
        '17_1_2', '17_1', '17_0_3', '17_0', '16_7_7', '16_7_5',
        '16_7_2', '16_6_1', '16_6', '16_5_1',
    ];
    const iOSSafariVersions = [
        '17.4', '17.3', '17.2', '17.1', '17.0', '16.7', '16.6', '16.5',
    ];

    const desktopWinVersions = [
        'Windows NT 10.0; Win64; x64',
        'Windows NT 11.0; Win64; x64',
    ];
    const desktopMacVersions = [
        'Macintosh; Intel Mac OS X 10_15_7',
        'Macintosh; Intel Mac OS X 14_4',
        'Macintosh; Intel Mac OS X 13_6',
    ];
    const desktopChromeVersions = [
        '125.0.0.0', '124.0.0.0', '123.0.0.0', '122.0.0.0', '121.0.0.0',
    ];

    if (isMobile) {
        const type = Math.random() < 0.65 ? 'android' : (Math.random() < 0.8 ? 'iphone' : 'ipad');
        if (type === 'android') {
            const device = rand(androidDevices);
            const androidVer = rand(androidVersions);
            const chromeVer = rand(chromeVersions);
            return `Mozilla/5.0 (Linux; Android ${androidVer}; ${device}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromeVer} Mobile Safari/537.36`;
        } else if (type === 'iphone') {
            const iosVer = rand(iOSVersions);
            const safariVer = rand(iOSSafariVersions);
            return `Mozilla/5.0 (iPhone; CPU iPhone OS ${iosVer} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/${safariVer} Mobile/15E148 Safari/604.1`;
        } else {
            const iosVer = rand(iOSVersions);
            const safariVer = rand(iOSSafariVersions);
            return `Mozilla/5.0 (iPad; CPU OS ${iosVer} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/${safariVer} Mobile/15E148 Safari/604.1`;
        }
    } else {
        const type = Math.random() < 0.6 ? 'windows' : (Math.random() < 0.6 ? 'mac' : 'linux');
        const chromeVer = rand(desktopChromeVersions);
        if (type === 'windows') {
            const winVer = rand(desktopWinVersions);
            return `Mozilla/5.0 (${winVer}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromeVer} Safari/537.36`;
        } else if (type === 'mac') {
            const macVer = rand(desktopMacVersions);
            return `Mozilla/5.0 (${macVer}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromeVer} Safari/537.36`;
        } else {
            return `Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromeVer} Safari/537.36`;
        }
    }
}

// ── Signal lists ──────────────────────────────────────────────────────────────

const CONTINUE_WORDS = [
    'continue', 'next', 'submit', 'search', 'find', 'send', 'ok', 'go',
    'চালিয়ে যান', 'চালিয়ে', 'পরবর্তী', 'জমা', 'খুঁজুন',
    'متابعة', 'التالي', 'إرسال', 'بحث',
    'जारी रखें', 'अगला', 'सबमिट', 'खोजें',
    'continuer', 'suivant', 'envoyer',
    'continuar', 'siguiente', 'enviar',
    'lanjutkan', 'berikutnya', 'kirim',
    'devam et', 'ileri', 'gönder',
    'tiếp tục', 'tiếp theo', 'gửi',
    'ต่อไป', 'ถัดไป', 'ส่ง',
    '계속', '다음', '제출',
    '続ける', '次へ', '送信',
    '继续', '下一步', '提交',
    'weiter', 'senden',
    'продолжить', 'далее', 'отправить',
];

const BLOCKED_WORDS = [
    'back', 'cancel', 'skip', 'close', 'not you', 'not me', 'whatsapp',
    'আপনি নন', 'إلغاء', 'cancelar', 'annuler', 'abbrechen', 'отмена', 'পিছনে',
];

const NO_ACCOUNT_PHRASES = [
    'no account found', "couldn't find", 'account not found',
    'কোনো অ্যাকাউন্ট', 'لا يوجد حساب', 'कोई खाता नहीं',
    'aucun compte', 'no encontramos', 'tidak menemukan',
    'hesap bulunamadı', 'không tìm thấy', 'аккаунт не найден',
];

const SMS_SIGNALS = [
    // English — specific phrases only (avoid 'get code', 'send code', 'phone' — too broad)
    'sms', 'text message', 'text me', 'send sms', 'send text',
    'code via sms', 'sms code', 'get code via sms', 'get code via text',
    'phone verification', 'verify by phone', 'phone verification code',
    'verification code', 'mobile code', 'phone code', 'receive sms',

    // Bengali
    'এসএমএস', 'এসএমএস-এর মাধ্যমে', 'কোড পান', 'ফোনে কোড পাঠান',
    'এসএমএস করুন', 'বার্তা পাঠান', 'ফোন নম্বর', 'যাচাই কোড',

    // Arabic
    'رسالة نصية', 'رسالة', 'رقم الهاتف', 'إرسال الكود', 'كود عبر الهاتف',
    'إرسال رسالة', 'رسالة نصية قصيرة', 'رمز التحقق', 'كود التحقق',

    // Hindi
    'एसएमएस', 'फोन नंबर', 'कोड भेजें', 'फोन पर कोड भेजें',
    'एसएमएस भेजें', 'संदेश भेजें', 'फोन वेरिफिकेशन', 'वेरिफिकेशन कोड',

    // Spanish
    'mensaje de texto', 'número de teléfono', 'enviar código', 'enviar por teléfono',
    'enviar sms', 'mensaje', 'código de verificación', 'verificar por teléfono',

    // French
    'par sms', 'message texte', 'numéro de téléphone', 'envoyer le code',
    'code par sms', 'code de vérification', 'téléphone',

    // Indonesian
    'pesan teks', 'nomor telepon', 'kirim kode', 'kirim melalui telepon',
    'kirim sms', 'pesan', 'kode verifikasi', 'verifikasi telepon',

    // Turkish
    'kısa mesaj', 'telefon numarası', 'kod gönder', 'telefonla gönder',
    'sms gönder', 'mesaj gönder', 'telefon doğrulama', 'doğrulama kodu',

    // Vietnamese
    'tin nhắn văn bản', 'số điện thoại', 'gửi mã', 'gửi qua điện thoại',
    'mã xác thực', 'xác thực qua điện thoại', 'mã sms',

    // Portuguese
    'mensagem de texto', 'número de telefone', 'enviar por telefone',
    'enviar sms', 'código de verificação', 'verificar telefone',

    // German
    'textnachricht', 'telefonnummer', 'code senden', 'per telefon',
    'nachricht senden', 'handynummer', 'prüfcode', 'telefonprüfung',

    // Russian
    'смс', 'текстовое сообщение', 'номер телефона', 'отправить смс',
    'код подтверждения', 'проверка по телефону', 'код через смс',

    // Generic safe patterns
    'mobile', 'cell', 'text message',
];

const EMAIL_SIGNALS = [
    'email', 'e-mail', 'mail', 'gmail', 'yahoo', 'outlook', 'hotmail',
    'ইমেইল', 'মেইল', 'ইমেল',
    'بريد إلكتروني', 'إيميل',
    'ईमेल',
    'courriel',
    'correo electrónico',
    'surat elektronik',
    'e-posta',
    'thư điện tử',
    'อีเมล',
    '이메일',
    '电子邮件', '邮箱',
];

const WHATSAPP_SIGNALS = [
    'whatsapp', 'whats app', 'watsapp',
    'واتساب', 'واتس اب',
    'व्हाट्सएप', 'व्हाट्सएप्प',
];

const CAPTCHA_PHRASES = [
    'captcha', 'robot', 'automated', 'unusual traffic',
    'verify you are human', 'security check', 'confirm your identity',
    'আমি রোবট নই', 'لست روبوتًا',
];

const RATELIMIT_PHRASES = [
    'too many requests', 'try again later', 'temporarily blocked',
    'you have been blocked', 'rate limit', 'too many attempts',
    'please wait', 'সাময়িকভাবে অবরুদ্ধ',
];

// Navigation/action buttons that are NEVER an SMS option
const HARD_SKIP_TEXTS = [
    'log in', 'login', 'sign in', 'sign up', 'create new account',
    'create account', 'try again', 'reload page', 'back', 'cancel',
    'not you', 'not me', 'forgot password', 'search by email',
    'find my account',
    'enter password', 'enter password to log in', 'enter a password',
    'enter your password', 'use your password',
];

const INPUT_SELECTORS = [
    'input[name="email"]',
    'input[type="tel"]',
    'input[type="email"]',
    'input[autocomplete="username"]',
    'input[placeholder*="mobile" i]',
    'input[placeholder*="phone" i]',
    'input[placeholder*="number" i]',
    'input[placeholder*="email" i]',
    '#identify-email',
    'input[name="identify"]',
    'input[type="text"]',
];

// ── Utilities ─────────────────────────────────────────────────────────────────

function isMobileDomain(domain) {
    return !domain.includes('www.facebook');
}

function isPhoneNumberElement(txt) {
    // Matches masked phone numbers like +937*****260 or +93 780 210 119
    return /^\+?[\d\s\-*().]{7,25}$/.test(txt.trim()) && /\d{3}/.test(txt);
}

async function saveScreenshot(page, number, folder, reason) {
    try {
        const fs = require('fs');
        const dir = `results/${folder}`;
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        const safe = number.replace(/[^\w]/g, '_');
        const ts = new Date().toISOString().replace(/[:.]/g, '-');
        const file = `${dir}/${safe}_${reason}_${ts}.png`;
        await page.screenshot({ path: file, fullPage: false, timeout: 5000, animations: 'disabled' });
        debug(`Screenshot saved: ${file}`);
    } catch (e) {
        debug(`Screenshot failed: ${e.message}`);
    }
}

async function findInput(page) {
    try {
        await page.waitForSelector(INPUT_SELECTORS.join(', '), {
            timeout: 8000, state: 'visible'
        });
    } catch (_) { }
    for (const sel of INPUT_SELECTORS) {
        try {
            const el = await page.$(sel);
            if (el && await el.isVisible()) return el;
        } catch (_) { }
    }
    return null;
}

async function clickContinue(page) {
    const btns = await page.$$('button, [role="button"], input[type="submit"], input[type="button"], a[role="button"]');
    let clicked = false;
    for (const btn of btns) {
        try {
            if (!await btn.isVisible()) continue;
            const txt = (await btn.innerText().catch(() =>
                btn.getAttribute('value').catch(() => '')
            ) || '').toLowerCase().trim();
            if (!txt) continue;
            if (BLOCKED_WORDS.some(w => txt.includes(w))) continue;
            if (CONTINUE_WORDS.some(w => txt === w || txt.includes(w))) {
                await btn.click({ force: true });
                clicked = true;
                break;
            }
        } catch (_) { }
    }

    if (!clicked) {
        const sub = await page.$('button[type="submit"], input[type="submit"]');
        if (sub && await sub.isVisible()) {
            await sub.click({ force: true });
            clicked = true;
        }
    }

    if (!clicked) return false;

    // Wait for the next page to load and verify the OTP step
    debug('Clicked continue, waiting for navigation and verification...');
    try {
        await page.waitForLoadState('domcontentloaded', { timeout: 10000 });
        await sleep(2000); // give it time to render errors if any

        const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();

        // Check for rate limits or errors that occurred AFTER clicking continue
        if (RATELIMIT_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Rate limit hit after SMS request');
        }
        if (CAPTCHA_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Captcha required after SMS request');
        }

        // Verify that the page actually asks for a code now (OTP successful)
        const codeInput = await page.$('input[name="n"], input[name="c"], input[type="text"], input[type="number"], input[placeholder*="code" i]');
        const codeTextPresent = ['code', '8-digit', '6-digit', 'enter', 'check your phone'].some(w => bodyText.includes(w));

        if (codeInput || codeTextPresent) {
            debug('Verified OTP code input screen');
            return true;
        }

        debug('Failed to verify OTP screen after clicking continue');
        return false;
    } catch (e) {
        debug(`Error verifying continue click: ${e.message}`);
        throw e;
    }
}

// ── Smart page-settle wait ────────────────────────────────────────────────────
// Waits until visible interactive element count stabilises (>=2) or timeout.
// Fixes the race condition where we scan while the page is still rendering.
async function waitForPageSettle(page, context) {
    const selector = 'button, [role="button"], [role="radio"], a, li, label, input[type="radio"]';
    const MIN_COUNT = 2;    // page must have at least this many visible elements
    const STABLE_MS = 600;  // how long count must not change
    const MAX_WAIT = 4000;
    const POLL_MS = 300;
    const start = Date.now();
    let prevCount = -1;
    let stableFor = 0;

    await sleep(500); // minimum initial wait

    while (Date.now() - start < MAX_WAIT) {
        try {
            const all = await page.$$(selector);
            let visibleCount = 0;
            for (const el of all) {
                if (await el.isVisible().catch(() => false)) visibleCount++;
            }
            if (visibleCount >= MIN_COUNT) {
                if (visibleCount === prevCount) {
                    stableFor += POLL_MS;
                    if (stableFor >= STABLE_MS) {
                        debug(`Page settled after ${Date.now() - start}ms (${visibleCount} elements) [${context}]`);
                        return;
                    }
                } else {
                    stableFor = 0;
                    prevCount = visibleCount;
                }
            } else {
                // Still loading — reset
                stableFor = 0;
                prevCount = -1;
            }
        } catch (_) { }
        await sleep(POLL_MS);
    }
    debug(`Page settle timeout reached [${context}]`);
}

// ── Password modal dismissal ──────────────────────────────────────────────────
async function dismissPasswordModal(page) {
    try {
        const dialog = await page.$('[role="dialog"][aria-modal="true"]');
        if (!dialog) return false;
        const dialogText = (await dialog.innerText().catch(() => '')).toLowerCase();
        if (!dialogText.includes('password')) return false;
        debug('Password modal detected — dismissing...');
        const dismissTexts = ['try again', 'close', 'cancel', 'dismiss', 'not now'];
        const dialogBtns = await dialog.$$('button, [role="button"], a');
        for (const btn of dialogBtns) {
            try {
                if (!await btn.isVisible()) continue;
                const txt = (await btn.innerText().catch(() => '')).toLowerCase().trim();
                const aria = (await btn.getAttribute('aria-label').catch(() => '') || '').toLowerCase();
                if (dismissTexts.some(w => txt === w || txt.includes(w) || aria.includes(w))) {
                    debug(`Dismissing password modal via: "${txt || aria}"`);
                    await btn.click({ force: true });
                    await sleep(600);
                    const stillThere = await page.$('[role="dialog"][aria-modal="true"]');
                    if (!stillThere) { debug('Password modal dismissed'); return true; }
                }
            } catch (_) { }
        }
        await page.keyboard.press('Escape');
        await sleep(500);
        return false;
    } catch (_) { return false; }
}

// ── Language-agnostic structure-based SMS detection ───────────────────────────
// Facebook's aria-labels are consistently in English across all page languages.
async function detectSMSByStructure(page) {
    try {
        const candidates = await page.$$('[role="radio"], [role="button"], button, li, label, input[type="radio"]');
        for (const el of candidates) {
            if (!await el.isVisible()) continue;
            const aria = (await el.getAttribute('aria-label').catch(() => '') || '').toLowerCase();
            const txt = (await el.innerText().catch(() => '')).toLowerCase().trim();

            const isSmsAria = aria.includes('sms') || aria.includes('text message') ||
                aria.includes('get code via sms') || aria.includes('get code or link via sms');
            const isSmsText = txt.includes('sms') || txt.includes('text message');

            const isWhatsapp = aria.includes('whatsapp') || txt.includes('whatsapp');
            const isEmail = aria.includes('email') || txt.includes('email') || txt.includes('@');
            const isNotif = aria.includes('notification') || txt.includes('notification');
            const isPassword = aria.includes('password') || txt.includes('password');

            if ((isSmsAria || isSmsText) && !isWhatsapp && !isEmail && !isNotif && !isPassword) {
                debug(`Structure-detected SMS: aria="${aria.slice(0, 60)}" txt="${txt.slice(0, 40)}"`);
                return el;
            }
        }
    } catch (e) {
        debug(`Structure detection error: ${e.message}`);
    }
    return null;
}

// ── OTP confirmation screen verifier ─────────────────────────────────────────
// Returns true only if Facebook actually loaded the 'Enter code' screen after clicking Continue
async function verifyOTPScreenAppeared(page) {
    const OTP_CONFIRM_PHRASES = [
        // English
        'enter the code', 'enter code', '6-digit', 'digit code', 'confirmation code',
        'we sent', 'we texted', 'we\'ve sent', 'sent a code', 'code to', 'sent you a',
        'enter the 6', 'enter your code', 'check your phone', 'confirm your',
        // Bengali
        'কোডটি লিখুন', 'কোড দিন', 'ফোনে পাঠানো', 'কোড পাঠানো', '৬ সংখ্যার',
        // Arabic
        'أدخل الرمز', 'رمز التأكيد', 'تم إرسال', 'أرسلنا', 'الرمز المرسل',
        // Hindi
        'कोड दर्ज', 'कोड एंटर', 'भेजा गया कोड', '6 अंकों',
        // Spanish
        'ingresa el código', 'código enviado', 'te enviamos', 'código de confirmación',
        // French
        'entrez le code', 'code envoyé', 'nous vous avons envoyé', 'code à',
        // Indonesian
        'masukkan kode', 'kode yang dikirim', 'kami mengirim', 'kode verifikasi',
        // Russian
        'введите код', 'код отправлен', 'мы отправили', 'код подтверждения',
    ];
    const maxWait = 10000;
    const pollInterval = 500;
    const start = Date.now();
    while (Date.now() - start < maxWait) {
        try {
            const body = (await page.innerText('body').catch(() => '')).toLowerCase();
            if (OTP_CONFIRM_PHRASES.some(p => body.includes(p))) {
                debug('Verified OTP code input screen appeared!');
                return true;
            }
        } catch (_) { }
        await sleep(pollInterval);
    }
    debug('OTP screen did NOT appear after 10 seconds — marking as failed');
    return false;
}

// ── Main SMS finder ───────────────────────────────────────────────────────────
async function trySMSAndContinue(page) {
    // ── Step 0: Dismiss any password modal ──
    await dismissPasswordModal(page);

    // ── Step 1: Fast path — language-agnostic structure detection ──
    // Uses Facebook's always-English aria-labels to find SMS (works on ALL locales)
    const structureSms = await detectSMSByStructure(page);
    if (structureSms) {
        debug('Structure-based SMS detected, clicking...');
        await dismissPasswordModal(page);
        try {
            await structureSms.click({ timeout: 5000 });
        } catch (_) {
            try { await structureSms.click({ force: true, timeout: 3000 }); } catch (_) { }
        }
        await sleep(2500); // Increased wait time to ensure radio button selection registers
        await dismissPasswordModal(page);
        if (await clickContinue(page)) {
            debug('Structure-based SMS submitted, verifying OTP screen...');
            return await verifyOTPScreenAppeared(page);
        }
    }

    // ── Step 2: Check if SMS radio already selected ──
    try {
        const checked = await page.$('input[type="radio"]:checked');
        if (checked) {
            const label = await page.$('label:has(input[type="radio"]:checked)');
            const lbl = label ? (await label.innerText().catch(() => '')).toLowerCase() : '';
            debug(`Already selected option: ${lbl}`);
            // Guard: never treat email/WhatsApp/notification pre-selection as SMS
            const isNonSms = ['email', 'whatsapp', 'notification', 'facebook notification',
                'password', 'authenticator'].some(w => lbl.includes(w));
            if (!isNonSms && SMS_SIGNALS.some(s => lbl.includes(s))) {
                debug('SMS already selected, continuing');
                await sleep(300);
                if (await clickContinue(page)) return await verifyOTPScreenAppeared(page);
            }
            if (!isNonSms && !['whatsapp', 'email', 'authenticator', 'app', 'google', 'microsoft'].some(w => lbl.includes(w))) {
                debug('Generic option selected, trying to continue');
                await sleep(300);
                if (await clickContinue(page)) return await verifyOTPScreenAppeared(page);
            }
        }
    } catch (_) { }

    // ── Step 3: Main scan — innerText + aria-label ONLY (no innerHTML contamination) ──
    debug('Searching for SMS options...');
    const candidates = await page.$$('input[type="radio"], [role="radio"], button, [role="button"], a, li, div[tabindex], label');
    debug(`Found ${candidates.length} potential elements to check`);

    for (const el of candidates) {
        try {
            if (!await el.isVisible()) continue;
            const txt = (await el.innerText().catch(() => '')).toLowerCase().trim();
            const aria = (await el.getAttribute('aria-label').catch(() => '') || '').toLowerCase().trim();
            const title = (await el.getAttribute('title').catch(() => '') || '').toLowerCase().trim();

            debug(`Checking element: text="${txt.slice(0, 60)}", aria="${aria.slice(0, 60)}"`);

            // ── Handle "See More" / "Try another way" FIRST (before any skip filters) ──
            if (['see more', 'more options', 'more ways'].some(s => txt === s || aria === s)) {
                debug(`Expanding "see more" to reveal hidden recovery options`);
                try {
                    await el.click();
                    await waitForPageSettle(page, 'see more');
                    await dismissPasswordModal(page);
                    debug('Re-scanning after "see more" expansion...');
                    return await trySMSAndContinue(page);
                } catch (e) { debug(`Error clicking see more: ${e.message.split('\n')[0]}`); }
                continue;
            }

            if (['try another way', 'use another method', 'other options'].some(s => txt === s || aria === s)) {
                debug(`Clicking "try another way" to find SMS`);
                try {
                    await el.click();
                    await waitForPageSettle(page, 'try another way');
                    await dismissPasswordModal(page);
                    return await trySMSAndContinue(page);
                } catch (e) { debug(`Error clicking try another way: ${e.message.split('\n')[0]}`); }
                continue;
            }

            // ── Hard skip: nav buttons ──
            if (HARD_SKIP_TEXTS.some(w => txt === w || aria === w)) {
                debug(`Skipping nav button: "${txt || aria}"`);
                continue;
            }

            // ── Skip WhatsApp ──
            if (WHATSAPP_SIGNALS.some(s => txt.includes(s) || aria.includes(s))) {
                debug(`Skipping WhatsApp option: "${txt.slice(0, 40)}"`);
                continue;
            }

            // ── Skip email ──
            if (EMAIL_SIGNALS.some(s => txt.includes(s) || aria.includes(s))) {
                debug(`Skipping email option: "${txt.slice(0, 40)}"`);
                continue;
            }

            // ── Skip authenticator apps ──
            if (['authenticator', 'google authenticator', 'microsoft authenticator', 'github'].some(s => txt.includes(s) || aria.includes(s))) {
                debug(`Skipping authenticator option: "${txt.slice(0, 40)}"`);
                continue;
            }

            // ── Skip Facebook notification recovery ──
            if (['facebook notification', 'logged in on another device'].some(s => txt.includes(s) || aria.includes(s))) {
                debug(`Skipping notification option: "${txt.slice(0, 40)}"`);
                continue;
            }

            // ── Phone number account-selection buttons ──
            // After "try another way", Facebook sometimes shows "+937*****260" as a button
            if (isPhoneNumberElement(txt) && txt.length < 25) {
                debug(`Phone number button detected: "${txt}" — clicking to proceed`);
                try {
                    await el.click();
                    await sleep(1200);
                    await dismissPasswordModal(page);
                    return await trySMSAndContinue(page);
                } catch (e) {
                    debug(`Error clicking phone number button: ${e.message.split('\n')[0]}`);
                }
                continue;
            }

            // ── Match SMS option ──
            if (SMS_SIGNALS.some(s => txt.includes(s) || aria.includes(s) || title.includes(s))) {
                debug(`SMS option found: "${txt.slice(0, 60)}" / aria="${aria.slice(0, 60)}"`);
                await dismissPasswordModal(page);
                try {
                    await el.click({ timeout: 5000 });
                } catch (clickErr) {
                    debug(`Direct click failed — trying force click`);
                    try { await el.click({ force: true, timeout: 3000 }); } catch (_) { }
                }
                await sleep(2500); // Increased wait time to ensure radio button selection registers
                await dismissPasswordModal(page);
                if (await clickContinue(page)) {
                    debug('SMS option successfully submitted, verifying OTP screen...');
                    return await verifyOTPScreenAppeared(page);
                }
            }
        } catch (e) {
            debug(`Error processing element: ${e.message.split('\n')[0]}`);
        }
    }

    debug('No direct SMS found, trying alternative phone-related elements');

    // ── Step 4: Alternative phone elements ──
    const phoneElements = await page.$$('button, [role="button"], a, div[onclick], span[onclick]');
    for (const el of phoneElements) {
        try {
            if (!await el.isVisible()) continue;
            const txt = (await el.innerText().catch(() => '')).toLowerCase();
            if (['phone', 'mobile', 'cell', 'sms', 'text'].some(s => txt.includes(s)) &&
                !BLOCKED_WORDS.some(w => txt.includes(w)) &&
                !HARD_SKIP_TEXTS.some(w => txt === w)) {
                debug(`Trying phone-related element: ${txt.slice(0, 40)}`);
                await el.click();
                await sleep(800);
                const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();
                if (SMS_SIGNALS.some(s => bodyText.includes(s))) {
                    debug('Alternative led to SMS options, trying again');
                    return await trySMSAndContinue(page);
                }
                await page.goBack().catch(() => { });
                await sleep(500);
            }
        } catch (_) { }
    }

    debug('No SMS option found after all attempts');
    return false;
}

// ── processNumber ─────────────────────────────────────────────────────────────
async function processNumber(number, domain, userAgent, proxyConfig) {
    const mobile = isMobileDomain(domain);
    // Always generate a fresh UA per task, matched to domain type (ignores pre-selected UA)
    const freshUA = generateUA(mobile);
    userAgent = freshUA;
    let context = null;
    let page = null;
    let fallbackDirect = false;

    try {
        const b = await getBrowser();
        if (!b) return { result: 'error', errorMsg: 'Browser failed to start' };

        // Playwright allows setting proxy per context
        const contextOpts = {
            userAgent,
            locale: 'en-US',
            timezoneId: 'Asia/Dhaka',
            viewport: mobile ? { width: 390, height: 844 } : { width: 1280, height: 800 },
            isMobile: mobile,
            hasTouch: mobile,
            ignoreHTTPSErrors: true,
            extraHTTPHeaders: { 'Accept-Language': 'en-US,en;q=0.9' },
            proxy: proxyConfig || undefined
        };
        context = await b.newContext(contextOpts);
        page = await context.newPage();

        if (proxyConfig) {
            debug(`Context created with proxy: ${proxyConfig.server}`);
        }

        // Block images/fonts for speed
        await page.route('**/*.{png,jpg,jpeg,gif,webp,svg,woff,woff2,ttf,otf}', r => r.abort());
        await page.route('**/{analytics,tracking,ads,doubleclick}**', r => r.abort());

        const url = `${domain}/login/identify?ctx=recover`;
        let navOk = false;
        try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
            navOk = true;
            debug(`Navigation succeeded with timeout: 20000ms, waitUntil: domcontentloaded`);
        } catch (e) {
            debug(`Navigation failed: timeout=20000ms, waitUntil=domcontentloaded, error=${e.message}`);

            // ── Network-down detection: pause and wait, don't discard ──
            const isNetworkDown =
                e.message.includes('ERR_NAME_NOT_RESOLVED') ||
                e.message.includes('ERR_INTERNET_DISCONNECTED') ||
                e.message.includes('ERR_NETWORK_CHANGED') ||
                e.message.includes('ERR_ADDRESS_UNREACHABLE');

            if (isNetworkDown) {
                debug(`Network appears down — pausing up to 3 min and retrying same page...`);
                const maxWait = 3 * 60 * 1000; // 3 minutes
                const pollInterval = 10000;    // check every 10s
                const waitStart = Date.now();
                let recovered = false;
                while (Date.now() - waitStart < maxWait) {
                    await sleep(pollInterval);
                    try {
                        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
                        debug(`Network recovered after ${Math.round((Date.now() - waitStart) / 1000)}s — resuming`);
                        navOk = true;
                        recovered = true;
                        break;
                    } catch (_) {
                        debug(`Still waiting for network... (${Math.round((Date.now() - waitStart) / 1000)}s elapsed)`);
                    }
                }
                if (!recovered) {
                    return { result: 'error', errorMsg: `Network down for 3+ minutes: ${e.message.split('\n')[0]}` };
                }
            }

            if (!navOk) {
                const isProxyError = e.message.includes('ERR_PROXY') ||
                    e.message.includes('ERR_CONNECTION') ||
                    e.message.includes('ERR_TUNNEL') ||
                    e.message.includes('ERR_TIMED_OUT') ||
                    e.message.includes('Timeout') ||
                    e.message.includes('ERR_ABORTED') ||
                    e.message.includes('ERR_SOCKS');

                // Make sure it fails fast if proxy specifically rejects or errors out
                if (proxyConfig && isProxyError) {
                    debug(`Proxy failed/timed out — aborting to trigger retry with new proxy.`);
                    return { result: 'error', errorMsg: `Proxy failure: ${e.message.split('\n')[0]}` };
                }
            }
        }

        if (!navOk) {
            try {
                // If it timed out but wasn't a dead-proxy error, we assume the HTML loaded enough to proceed
                await page.goto(url, { timeout: 5000, waitUntil: 'commit' }).catch(() => { });
                await sleep(1000);
                navOk = true;
                debug('Final fallback navigation attempt');
            } catch (e) {
                return { result: 'error', errorMsg: `All navigation attempts failed: ${e.message}` };
            }
        }

        await sleep(rand(800, 1500));

        // Dismiss cookie dialogs
        for (const txt of ['Allow essential', 'Allow all', 'Accept all', 'OK', 'Got it', 'Allow']) {
            try {
                const btn = await page.$(`button:has-text("${txt}")`);
                if (btn && await btn.isVisible()) {
                    await btn.click();
                    await sleep(300);
                    break;
                }
            } catch (_) { }
        }

        const input = await findInput(page);
        if (!input) {
            await saveScreenshot(page, number, 'failed', 'no_input');
            return { result: 'error', errorMsg: 'Input not found' };
        }

        try {
            await input.click({ clickCount: 3, force: true, timeout: 5000 });
        } catch (_) { }
        await input.fill(number, { force: true });
        await sleep(rand(200, 400));

        const cont = await clickContinue(page);
        if (!cont) return { result: 'error', errorMsg: 'Continue not found' };

        // ── Smart wait: poll until aria="loading..." disappears ──
        // Replaces fixed 3-5s sleep so we never scan while the page is still processing
        {
            const LOAD_POLL = 400;
            const LOAD_MAX = 12000;
            const loadStart = Date.now();
            await sleep(1200); // minimum wait
            while (Date.now() - loadStart < LOAD_MAX) {
                try {
                    const loadingEl = await page.$('[aria-label="loading..."], [aria-busy="true"], [aria-label*="loading"]');
                    if (!loadingEl) {
                        debug(`Page load complete after ${Date.now() - loadStart}ms`);
                        break;
                    }
                } catch (_) { break; }
                await sleep(LOAD_POLL);
            }
            // Extra buffer for DOM to fully render recovery options
            await sleep(rand(800, 1500));
        }

        const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();

        if (NO_ACCOUNT_PHRASES.some(p => bodyText.includes(p))) {
            await saveScreenshot(page, number, 'failed', 'no_account');
            return { result: 'no_account', errorMsg: '' };
        }

        if (CAPTCHA_PHRASES.some(p => bodyText.includes(p))) {
            await saveScreenshot(page, number, 'failed', 'captcha');
            return { result: 'captcha', errorMsg: 'Captcha detected' };
        }

        if (RATELIMIT_PHRASES.some(p => bodyText.includes(p)))
            return { result: 'error', errorMsg: 'rate limit detected' };

        const sent = await trySMSAndContinue(page);
        if (sent) {
            debug('OTP #1 confirmed. Attempting 2 more sends for reliability...');
            await saveScreenshot(page, number, 'success', 'otp_sent_1');

            // ── 3x OTP Send Loop ────────────────────────────────────────────
            // After first confirmed send, go back and repeat 2 more times.
            // Facebook sometimes only dispatches the SMS on the 2nd or 3rd trigger.
            for (let attempt = 2; attempt <= 3; attempt++) {
                try {
                    await sleep(3000); // Give Facebook time to process before going back
                    // Navigate back to the SMS selection page
                    await page.goBack({ waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => { });
                    await sleep(1000);
                    // Try to send again
                    const reSent = await trySMSAndContinue(page);
                    if (reSent) {
                        debug(`OTP #${attempt} confirmed.`);
                        await saveScreenshot(page, number, 'success', `otp_sent_${attempt}`);
                    } else {
                        debug(`OTP #${attempt} — could not re-trigger SMS, stopping loop.`);
                        break;
                    }
                } catch (e) {
                    debug(`OTP re-send attempt ${attempt} error: ${e.message.split('\n')[0]}`);
                    break;
                }
            }

            debug('All OTP sends complete. Waiting 5s before closing...');
            await sleep(5000);
            return { result: 'success', errorMsg: '' };
        }

        // ── Fallback: save screenshot then try account-row selection ──
        debug('Primary SMS attempt failed, trying alternative methods');
        await saveScreenshot(page, number, 'failed', 'no_sms_primary');

        try {
            const sendButtons = await page.$$('button, [role="button"], a');
            for (const btn of sendButtons) {
                if (!await btn.isVisible()) continue;
                const txt = (await btn.innerText().catch(() => '')).toLowerCase();
                if (['send code', 'send sms', 'send verification'].some(s => txt.includes(s))) {
                    debug(`Found send code button: ${txt}`);
                    await btn.click();
                    await sleep(2000);
                    const body = (await page.innerText('body').catch(() => '')).toLowerCase();
                    if (body.includes('sent') || body.includes('code') || body.includes('sms')) {
                        debug('OTP confirmed via alternative send button. Waiting 5 seconds before closing browser...');
                        await saveScreenshot(page, number, 'success', 'otp_sent_alt');
                        await sleep(5000);
                        return { result: 'success', errorMsg: '' };
                    }
                }
            }
        } catch (_) { }

        return { result: 'no_sms', errorMsg: '' };

    } catch (err) {
        debug(`Process number error: ${err.message}`);
        return { result: 'error', errorMsg: err.message };
    } finally {
        if (context) {
            try { await context.close(); } catch (e) {
                debug(`Error closing context: ${e.message}`);
            }
        }
    }
}

// ── Message handler ───────────────────────────────────────────────────────────
parentPort.on('message', async (msg) => {
    try {
        await loadPlaywright();
        const { number, proxy, domain, userAgent, language } = msg;

        const safeDomain = (domain && typeof domain === 'string') ? domain : 'https://www.facebook.com';
        debug(`Processing ${number} with domain: ${safeDomain}`);

        const proxyConfig = proxy ? parseProxy(proxy) : null;
        if (proxy && !proxyConfig) {
            debug(`Invalid proxy format: ${proxy}, falling back to direct connection`);
        }

        const { result, errorMsg } = await processNumber(number, safeDomain, userAgent, proxyConfig);
        parentPort.postMessage({ type: 'result', number, result, errorMsg, language,
            // Report the proxy back so main thread can blacklist it on failure
            proxy: proxyConfig ? proxyConfig.server : null
        });
    } catch (err) {
        debug(`Worker message handler error: ${err.message}`);
        parentPort.postMessage({
            type: 'result', number: msg.number,
            result: 'error', errorMsg: 'crash: ' + err.message,
        });
    }
});

// ── Cleanup ───────────────────────────────────────────────────────────────────
process.on('exit', () => {
    if (browser) { try { browser.close(); } catch (e) { } }
});

process.on('uncaughtException', (err) => {
    debug(`Uncaught exception in worker: ${err.message}`);
    if (browser) { try { browser.close(); } catch (e) { } }
    process.exit(1);
});
