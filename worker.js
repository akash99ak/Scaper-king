// ============================================================
//  Worker — One persistent browser, clears session per number
//  v2.0 — Fixed false-OTP bug, 5x resend, account selection,
//          mbasic-first, sticky IP + UA per number
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

    const getProtocol = (port) => port === '33335' ? 'https' : 'http';

    try {
        if (proxyStr.includes('@')) {
            const [creds, hp] = proxyStr.split('@');
            if (!creds || !hp) return null;
            const [username, password] = creds.split(':');
            const [host, port] = hp.split(':');
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `${getProtocol(port)}://${host}:${port}`, username, password: password || '' };
        }
        const parts = proxyStr.split(':');
        if (parts.length === 4) {
            const [host, port, username, password] = parts;
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `${getProtocol(port)}://${host}:${port}`, username, password: password || '' };
        }
        if (parts.length === 3) {
            const [host, port, username] = parts;
            if (!host || !port || !username) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `${getProtocol(port)}://${host}:${port}`, username, password: '' };
        }
        if (parts.length === 2) {
            const [host, port] = parts;
            if (!host || !port) return null;
            const portNum = parseInt(port);
            if (isNaN(portNum) || portNum < 1 || portNum > 65535) return null;
            return { server: `${getProtocol(port)}://${host}:${port}` };
        }
    } catch (e) {
        return null;
    }
    return null;
}

// ── Dynamic UA Generator ─────────────────────────────────────────────────────
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
    'sms', 'text message', 'text me', 'send sms', 'send text',
    'code via sms', 'sms code', 'get code via sms', 'get code via text',
    'phone verification', 'verify by phone', 'phone verification code',
    'verification code', 'mobile code', 'phone code', 'receive sms',
    // Bengali
    'এসএমএস', 'এসএমএস-এর মাধ্যমে', 'কোড পান', 'ফোনে কোড পাঠান',
    // Arabic
    'رسالة نصية', 'رسالة', 'رقم الهاتف', 'إرسال الكود', 'كود عبر الهاتف',
    'رسالة نصية قصيرة', 'رمز التحقق',
    // Hindi
    'एसएमएस', 'फोन नंबर', 'कोड भेजें', 'फोन पर कोड भेजें',
    // Spanish
    'mensaje de texto', 'número de teléfono', 'enviar código',
    // French
    'par sms', 'message texte', 'numéro de téléphone', 'envoyer le code',
    // Indonesian
    'pesan teks', 'nomor telepon', 'kirim kode', 'kode verifikasi',
    // Turkish
    'kısa mesaj', 'telefon numarası', 'kod gönder',
    // Vietnamese
    'tin nhắn văn bản', 'số điện thoại', 'gửi mã', 'mã xác thực',
    // Portuguese
    'mensagem de texto', 'número de telefone', 'código de verificação',
    // German
    'textnachricht', 'telefonnummer', 'code senden', 'prüfcode',
    // Russian
    'смс', 'текстовое сообщение', 'номер телефона', 'код подтверждения',
    // Generic
    'mobile', 'cell',
];

const EMAIL_SIGNALS = [
    'email', 'e-mail', 'mail', 'gmail', 'yahoo', 'outlook', 'hotmail',
    'ইমেইল', 'مেইল', 'ইমেল',
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
    'व्हाट्सएप',
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

// ── OTP confirmation phrases ──────────────────────────────────────────────────
const OTP_CONFIRM_PHRASES = [
    // English
    'enter the code', 'enter code', '6-digit', 'digit code', 'confirmation code',
    'we sent', 'we texted', "we've sent", 'sent a code', 'code to', 'sent you a',
    'enter the 6', 'enter your code', 'check your phone', 'confirm your',
    // Bengali
    'কোডটি লিখুন', 'কোড দিন', 'ফোনে পাঠানো', 'কোড পাঠানো', '৬ সংখ্যার',
    // Arabic
    'أدخل الرمز', 'رمز التأكيد', 'تم إرسال', 'أرسلنا', 'الرمز المرسل',
    // Hindi
    'कोड दर्ज', 'कोड एंटर', 'भेजा गया कोड', '6 अंकों',
    // Spanish
    'ingresa el código', 'código enviado', 'te enviamos',
    // French
    'entrez le code', 'code envoyé', 'nous vous avons envoyé',
    // Indonesian
    'masukkan kode', 'kode yang dikirim', 'kami mengirim',
    // Russian
    'введите код', 'код отправлен', 'мы отправили',
];

// ── Utilities ─────────────────────────────────────────────────────────────────

function isMobileDomain(domain) {
    return !domain.includes('www.facebook');
}

function isPhoneNumberElement(txt) {
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

// ── FIXED: clickAndAdvance — used AFTER phone number entry ────────────────────
// Only clicks the button and confirms we left the identify page.
// Does NOT check for OTP screen (that's wrong here — we're going to recovery options).
async function clickAndAdvance(page) {
    // Selectors: standard buttons + mbasic anchor links (mbasic uses <a> not <button>)
    const btns = await page.$$('button, [role="button"], input[type="submit"], input[type="button"], a[role="button"], a[href]');
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
                const navPromise = page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});
                await btn.click({ force: true });
                await navPromise;
                clicked = true;
                debug(`clickAndAdvance: clicked "${txt}"`);
                break;
            }
        } catch (_) { }
    }

    if (!clicked) {
        const sub = await page.$('button[type="submit"], input[type="submit"]');
        if (sub && await sub.isVisible()) {
            const navPromise = page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});
            await sub.click({ force: true });
            await navPromise;
            clicked = true;
            debug('clickAndAdvance: clicked submit fallback');
        }
    }

    if (!clicked) {
        debug('clickAndAdvance: no button found');
        return false;
    }

    // Wait a brief moment for dynamic elements to settle after navigation
    try {
        await sleep(1500);

        const url = page.url();
        const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();

        // Check for hard fails
        if (RATELIMIT_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Rate limit hit after advancing');
        }
        if (CAPTCHA_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Captcha required after advancing');
        }

        // Bad: still on identify page (nothing happened)
        if (url.includes('/login/identify') && bodyText.includes('find your account')) {
            debug('clickAndAdvance: still on identify page — button click failed');
            return false;
        }

        debug(`clickAndAdvance: advanced to ${url}`);
        return true;
    } catch (e) {
        debug(`clickAndAdvance error: ${e.message}`);
        if (e.message.includes('Rate limit') || e.message.includes('Captcha')) throw e;
        return false;
    }
}

// ── clickAndVerifyOTP — used AFTER SMS option is selected ────────────────────
// Clicks the Continue/Submit button and verifies the OTP code screen appeared.
async function clickAndVerifyOTP(page) {
    const btns = await page.$$('button, [role="button"], input[type="submit"], input[type="button"], a[role="button"], a[href]');
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
                const navPromise = page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});
                await btn.click({ force: true });
                await navPromise;
                clicked = true;
                debug(`clickAndVerifyOTP: clicked "${txt}"`);
                break;
            }
        } catch (_) { }
    }

    if (!clicked) {
        const sub = await page.$('button[type="submit"], input[type="submit"]');
        if (sub && await sub.isVisible()) {
            const navPromise = page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});
            await sub.click({ force: true });
            await navPromise;
            clicked = true;
            debug('clickAndVerifyOTP: clicked submit fallback');
        }
    }

    if (!clicked) return false;

    debug('clickAndVerifyOTP: waiting for OTP screen...');
    try {
        await sleep(1500);

        const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();

        if (RATELIMIT_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Rate limit hit after SMS request');
        }
        if (CAPTCHA_PHRASES.some(w => bodyText.includes(w))) {
            throw new Error('Captcha required after SMS request');
        }

        // Must be OTP code input — strict check
        const codeInput = await page.$('input[name="n"], input[name="c"], input[placeholder*="code" i]');
        const codeTextPresent = OTP_CONFIRM_PHRASES.some(w => bodyText.includes(w));

        if (codeInput || codeTextPresent) {
            debug('clickAndVerifyOTP: OTP screen confirmed ✓');
            return true;
        }

        debug('clickAndVerifyOTP: OTP screen did NOT appear');
        return false;
    } catch (e) {
        debug(`clickAndVerifyOTP error: ${e.message}`);
        throw e;
    }
}

// ── Smart page-settle wait ────────────────────────────────────────────────────
async function waitForPageSettle(page, context) {
    const selector = 'button, [role="button"], [role="radio"], a, li, label, input[type="radio"]';
    const MIN_COUNT = 2;
    const STABLE_MS = 600;
    const MAX_WAIT = 4000;
    const POLL_MS = 300;
    const start = Date.now();
    let prevCount = -1;
    let stableFor = 0;

    await sleep(500);

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

// ── Structure-based SMS detection ─────────────────────────────────────────────
async function detectSMSByStructure(page, targetNumber) {
    try {
        const candidates = await page.$$('[role="radio"], [role="button"], button, li, label, input[type="radio"]');
        let fallbackSmsEl = null;

        for (const el of candidates) {
            if (!await el.isVisible()) continue;
            const aria = (await el.getAttribute('aria-label').catch(() => '') || '').toLowerCase();
            const txt = (await el.innerText().catch(() => '')).toLowerCase().trim();

            const isSmsAria = SMS_SIGNALS.some(s => aria.includes(s));
            const isSmsText = SMS_SIGNALS.some(s => txt.includes(s));

            const isWhatsapp = WHATSAPP_SIGNALS.some(s => aria.includes(s) || txt.includes(s));
            const isEmail = EMAIL_SIGNALS.some(s => aria.includes(s) || txt.includes(s));

            const isNotif = aria.includes('notification') || txt.includes('notification') || aria.includes('facebook') || txt.includes('ফেসবুক') || txt.includes('إشعار');
            const isPassword = aria.includes('password') || txt.includes('password') || txt.includes('سري') || txt.includes('كلمة') || txt.includes('سیسم') || txt.includes('পাসওয়ার্ড');

            if ((isSmsAria || isSmsText) && !isWhatsapp && !isEmail && !isNotif && !isPassword) {
                const targetSuffix = targetNumber ? targetNumber.slice(-2) : 'XX';
                if (txt.includes(targetSuffix) || aria.includes(targetSuffix)) {
                    debug(`Structure-detected SMS (exact suffix match for ${targetSuffix}): aria="${aria.slice(0, 60)}" txt="${txt.slice(0, 40)}"`);
                    return el;
                }
                if (!fallbackSmsEl) {
                    debug(`Structure-detected SMS (generic match): aria="${aria.slice(0, 60)}" txt="${txt.slice(0, 40)}"`);
                    fallbackSmsEl = el;
                }
            }
        }
        return fallbackSmsEl;
    } catch (e) {
        debug(`Structure detection error: ${e.message}`);
    }
    return null;
}

// ── OTP confirmation screen verifier ─────────────────────────────────────────
async function verifyOTPScreenAppeared(page) {
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

// ── Multiple-account selection ────────────────────────────────────────────────
// When Facebook shows a list of accounts matching the phone number,
// scan each row, select the one with an SMS recovery option (not email-only),
// then proceed. Returns true if an account was selected.
async function selectBestAccountForSMS(page) {
    try {
        // Common account-row selectors on mbasic / m / www
        const accountRows = await page.$$('[data-sigil="account"], [role="listitem"] a, ul.uiList li a, .account-selection-list a');
        if (accountRows.length === 0) return false;

        debug(`Found ${accountRows.length} account rows — scanning for SMS recovery`);

        // Fast path: try each row and look for SMS indicator
        for (const row of accountRows) {
            try {
                if (!await row.isVisible()) continue;
                const txt = (await row.innerText().catch(() => '')).toLowerCase();

                // Skip rows that look email-only
                if (EMAIL_SIGNALS.some(s => txt.includes(s)) && !SMS_SIGNALS.some(s => txt.includes(s))) {
                    debug(`Account row skipped (email-only): ${txt.slice(0, 40)}`);
                    continue;
                }

                // Click this row
                debug(`Selecting account row: ${txt.slice(0, 60)}`);
                await row.click();
                await sleep(1500);
                return true;
            } catch (_) { }
        }

        // Fallback: click first visible row
        for (const row of accountRows) {
            if (!await row.isVisible().catch(() => false)) continue;
            const txt = (await row.innerText().catch(() => '')).slice(0, 40);
            debug(`Account fallback: selecting first row: ${txt}`);
            await row.click();
            await sleep(1500);
            return true;
        }
    } catch (e) {
        debug(`selectBestAccountForSMS error: ${e.message}`);
    }
    return false;
}

// ── Main SMS finder ───────────────────────────────────────────────────────────
async function trySMSAndContinue(page, targetNumber) {
    // Step 0: Dismiss any password modal
    await dismissPasswordModal(page);

    // Step 1: Fast path — structure-based detection
    const structureSms = await detectSMSByStructure(page, targetNumber);
    if (structureSms) {
        debug('Structure-based SMS detected, clicking...');
        await dismissPasswordModal(page);
        try {
            await structureSms.click({ timeout: 5000 });
        } catch (_) {
            try { await structureSms.click({ force: true, timeout: 3000 }); } catch (_) { }
        }
        await sleep(2500);
        await dismissPasswordModal(page);
        if (await clickAndVerifyOTP(page)) {
            debug('Structure-based SMS submitted, OTP screen confirmed');
            return true;
        }
    }

    // Step 2: Check if SMS radio already selected
    try {
        const checked = await page.$('input[type="radio"]:checked');
        if (checked) {
            const label = await page.$('label:has(input[type="radio"]:checked)');
            const lbl = label ? (await label.innerText().catch(() => '')).toLowerCase() : '';
            const isNonSms = ['email', 'whatsapp', 'notification', 'facebook notification',
                'password', 'authenticator'].some(w => lbl.includes(w));
            if (!isNonSms && SMS_SIGNALS.some(s => lbl.includes(s))) {
                debug('SMS already selected, continuing');
                await sleep(300);
                if (await clickAndVerifyOTP(page)) return true;
            }
            if (!isNonSms && !['whatsapp', 'email', 'authenticator', 'app', 'google', 'microsoft'].some(w => lbl.includes(w))) {
                debug('Generic option selected, trying to continue');
                await sleep(300);
                if (await clickAndVerifyOTP(page)) return true;
            }
        }
    } catch (_) { }

    // Step 3: Full element scan
    debug('Searching for SMS options...');
    const candidates = await page.$$('input[type="radio"], [role="radio"], button, [role="button"], a, li, div[tabindex], label');
    debug(`Found ${candidates.length} potential elements to check`);

    for (const el of candidates) {
        try {
            if (!await el.isVisible()) continue;
            const txt = (await el.innerText().catch(() => '')).toLowerCase().trim();
            const aria = (await el.getAttribute('aria-label').catch(() => '') || '').toLowerCase().trim();
            const title = (await el.getAttribute('title').catch(() => '') || '').toLowerCase().trim();

            // Expand "see more" first
            if (['see more', 'more options', 'more ways'].some(s => txt === s || aria === s)) {
                debug('Expanding "see more"');
                try {
                    await el.click();
                    await waitForPageSettle(page, 'see more');
                    await dismissPasswordModal(page);
                    return await trySMSAndContinue(page, targetNumber);
                } catch (e) { debug(`see more error: ${e.message.split('\n')[0]}`); }
                continue;
            }

            if (['try another way', 'use another method', 'other options'].some(s => txt === s || aria === s)) {
                debug('Clicking "try another way"');
                try {
                    await el.click();
                    await waitForPageSettle(page, 'try another way');
                    await dismissPasswordModal(page);
                    return await trySMSAndContinue(page, targetNumber);
                } catch (e) { debug(`try another way error: ${e.message.split('\n')[0]}`); }
                continue;
            }

            if (HARD_SKIP_TEXTS.some(w => txt === w || aria === w)) continue;
            if (WHATSAPP_SIGNALS.some(s => txt.includes(s) || aria.includes(s))) continue;
            if (EMAIL_SIGNALS.some(s => txt.includes(s) || aria.includes(s))) continue;
            if (['authenticator', 'google authenticator', 'microsoft authenticator', 'github'].some(s => txt.includes(s) || aria.includes(s))) continue;
            if (['facebook notification', 'logged in on another device'].some(s => txt.includes(s) || aria.includes(s))) continue;

            // Phone number button (after "try another way")
            if (isPhoneNumberElement(txt) && txt.length < 25) {
                debug(`Phone number button: "${txt}" — clicking`);
                try {
                    await el.click();
                    await sleep(1200);
                    await dismissPasswordModal(page);
                    return await trySMSAndContinue(page, targetNumber);
                } catch (e) { debug(`Phone btn error: ${e.message.split('\n')[0]}`); }
                continue;
            }

            // SMS match
            if (SMS_SIGNALS.some(s => txt.includes(s) || aria.includes(s) || title.includes(s))) {
                const targetSuffix = targetNumber ? targetNumber.slice(-2) : 'XX';
                const isExact = txt.includes(targetSuffix) || aria.includes(targetSuffix) || title.includes(targetSuffix);
                
                debug(`SMS option found (exact=${isExact}): "${txt.slice(0, 60)}" / aria="${aria.slice(0, 60)}"`);
                await dismissPasswordModal(page);
                try {
                    await el.click({ timeout: 5000 });
                } catch (_) {
                    try { await el.click({ force: true, timeout: 3000 }); } catch (_) { }
                }
                
                // If it's a perfect match, confidently break and process it.
                // If we aren't sure, we click it but keep scanning just in case a better one exists.
                if (isExact) {
                    await sleep(2500);
                    await dismissPasswordModal(page);
                    if (await clickAndVerifyOTP(page)) {
                        debug('SMS submitted, OTP screen confirmed ✓');
                        return true;
                    }
                } else {
                    // It didn't match the suffix, but we clicked it. We'll give it a shot.
                    await sleep(1500);
                    if (await clickAndVerifyOTP(page)) return true;
                }
            }
        } catch (e) {
            debug(`Element scan error: ${e.message.split('\n')[0]}`);
        }
    }

    // Step 4: Alternative phone elements
    debug('No direct SMS found, trying alternative phone elements');
    const phoneElements = await page.$$('button, [role="button"], a, div[onclick], span[onclick]');
    for (const el of phoneElements) {
        try {
            if (!await el.isVisible()) continue;
            const txt = (await el.innerText().catch(() => '')).toLowerCase();
            if (SMS_SIGNALS.some(s => txt.includes(s)) &&
                !BLOCKED_WORDS.some(w => txt.includes(w)) &&
                !HARD_SKIP_TEXTS.some(w => txt === w)) {
                debug(`Trying phone element: ${txt.slice(0, 40)}`);
                await el.click();
                await sleep(800);
                const bodyText = (await page.innerText('body').catch(() => '')).toLowerCase();
                if (SMS_SIGNALS.some(s => bodyText.includes(s))) {
                    return await trySMSAndContinue(page, targetNumber);
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
// SMS_RESEND_COUNT: how many times to trigger the SMS send (5 times total)
// All 5 sends use the SAME browser context / SAME IP / SAME UA
const SMS_RESEND_COUNT = 5;
const SMS_RESEND_WAIT_MS_MIN = 5000; // 5s min wait before going back
const SMS_RESEND_WAIT_MS_MAX = 7000; // 7s max wait before going back

async function processNumber(number, domain, userAgent, proxyConfig, language) {
    const mobile = isMobileDomain(domain);

    // ── STICKY UA: generate ONE fresh UA at the start, never change it mid-session ──
    const freshUA = generateUA(mobile);
    userAgent = freshUA;
    debug(`UA for this session: ${freshUA.slice(0, 60)}...`);

    let context = null;
    let page = null;

    try {
        const b = await getBrowser();
        if (!b) return { result: 'error', errorMsg: 'Browser failed to start' };

        const localeMap = {
            'pt': 'pt-BR', 'es': 'es-MX', 'fr': 'fr-FR', 'ar': 'ar-EG',
            'bn': 'bn-BD', 'id': 'id-ID', 'vi': 'vi-VN', 'tr': 'tr-TR',
            'ru': 'ru-RU', 'de': 'de-DE', 'hi': 'hi-IN', 'zh': 'zh-CN',
            'ja': 'ja-JP', 'ko': 'ko-KR', 'en': 'en-US'
        };
        const browserLocale = localeMap[language] || 'en-US';

        // ── STICKY IP: proxy is set once at context level, reused for ALL 5 resends ──
        const contextOpts = {
            userAgent,
            locale: browserLocale,
            timezoneId: 'Asia/Dhaka',
            viewport: mobile ? { width: 390, height: 844 } : { width: 1280, height: 800 },
            isMobile: mobile,
            hasTouch: mobile,
            ignoreHTTPSErrors: true,
            extraHTTPHeaders: { 'Accept-Language': `${browserLocale},${language};q=0.9,en-US;q=0.8,en;q=0.7` },
            proxy: proxyConfig || undefined
        };
        context = await b.newContext(contextOpts);
        page = await context.newPage();

        if (proxyConfig) {
            debug(`Context created with proxy: ${proxyConfig.server} (sticky for all resends)`);
        }

        // Block images/fonts for speed
        await page.route('**/*.{png,jpg,jpeg,gif,webp,svg,woff,woff2,ttf,otf}', r => r.abort());
        await page.route('**/{analytics,tracking,ads,doubleclick}**', r => r.abort());

        const url = `${domain}/login/identify?ctx=recover`;
        let navOk = false;
        try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
            navOk = true;
            debug(`Navigation succeeded`);
        } catch (e) {
            debug(`Navigation failed: ${e.message.split('\n')[0]}`);

            const isNetworkDown =
                e.message.includes('ERR_NAME_NOT_RESOLVED') ||
                e.message.includes('ERR_INTERNET_DISCONNECTED') ||
                e.message.includes('ERR_NETWORK_CHANGED') ||
                e.message.includes('ERR_ADDRESS_UNREACHABLE');

            if (isNetworkDown) {
                debug(`Network appears down — pausing up to 3 min and retrying...`);
                const maxWait = 3 * 60 * 1000;
                const pollInterval = 10000;
                const waitStart = Date.now();
                let recovered = false;
                while (Date.now() - waitStart < maxWait) {
                    await sleep(pollInterval);
                    try {
                        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
                        debug(`Network recovered after ${Math.round((Date.now() - waitStart) / 1000)}s`);
                        navOk = true;
                        recovered = true;
                        break;
                    } catch (_) { }
                }
                if (!recovered) {
                    return { result: 'error', errorMsg: `Network down for 3+ minutes` };
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

                if (proxyConfig && isProxyError) {
                    debug(`Proxy failed/timed out — aborting`);
                    return { result: 'error', errorMsg: `Proxy failure: ${e.message.split('\n')[0]}` };
                }
            }
        }

        if (!navOk) {
            try {
                await page.goto(url, { timeout: 5000, waitUntil: 'commit' }).catch(() => { });
                await sleep(1000);
                navOk = true;
                debug('Final fallback navigation');
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
            try {
                const dbgUrl = page.url();
                const dbgTxt = await page.innerText('body').catch(() => 'no text');
                debug(`[NO_INPUT_DEBUG] URL: ${dbgUrl} | Content: ${dbgTxt.replace(/\\n/g, ' ').substring(0, 500)}`);
            } catch (e) {}
            await saveScreenshot(page, number, 'failed', 'no_input');
            return { result: 'error', errorMsg: 'Input not found' };
        }

        try {
            await input.click({ clickCount: 3, force: true, timeout: 5000 });
        } catch (_) { }
        await input.fill(number, { force: true });
        await sleep(rand(300, 600));

        // ── FIXED: use clickAndAdvance (does NOT check OTP here) ──
        const advanced = await clickAndAdvance(page);
        if (!advanced) return { result: 'error', errorMsg: 'Continue not found or did not advance' };

        // Smart wait for recovery options page to load
        {
            const LOAD_POLL = 400;
            const LOAD_MAX = 12000;
            const loadStart = Date.now();
            await sleep(1200);
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

        // ── Multiple account selection ──
        // Facebook sometimes shows multiple account rows when the phone matches multiple accounts.
        // Scan for the one most likely to have SMS recovery.
        const pageUrl = page.url();
        if (pageUrl.includes('/recover') && bodyText.includes('choose') ||
            bodyText.includes('more than one account') ||
            bodyText.includes('multiple accounts') ||
            bodyText.includes('which account')) {
            debug('Multiple accounts detected — selecting best for SMS');
            const selected = await selectBestAccountForSMS(page);
            if (selected) {
                await sleep(rand(1200, 2000));
                // Re-check for no-account / captcha after selection
                const newBody = (await page.innerText('body').catch(() => '')).toLowerCase();
                if (NO_ACCOUNT_PHRASES.some(p => newBody.includes(p))) {
                    return { result: 'no_account', errorMsg: '' };
                }
            }
        }

        // ── 5x SMS Send Loop ─────────────────────────────────────────────────
        // Find SMS option and trigger it. If confirmed, go back and resend up to 5x total.
        // Same context (same IP, same UA) used throughout all 5 sends.
        let successCount = 0;
        let smsPageUrl = null; // URL of the recovery options page (used to go back)

        for (let attempt = 1; attempt <= SMS_RESEND_COUNT; attempt++) {
            debug(`SMS send attempt ${attempt}/${SMS_RESEND_COUNT}...`);

            // On resend attempts, navigate back to recovery options page
            if (attempt > 1) {
                if (smsPageUrl) {
                    try {
                        await page.goto(smsPageUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
                        await sleep(rand(SMS_RESEND_WAIT_MS_MIN, SMS_RESEND_WAIT_MS_MAX));
                        debug(`Resend attempt ${attempt}: navigated back to recovery options`);
                    } catch (e) {
                        debug(`Resend attempt ${attempt}: navigation back failed — ${e.message.split('\n')[0]}`);
                        // Try goBack as fallback
                        try {
                            await page.goBack({ waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => { });
                            await sleep(rand(SMS_RESEND_WAIT_MS_MIN, SMS_RESEND_WAIT_MS_MAX));
                        } catch (_) { }
                    }
                } else {
                    debug(`Resend attempt ${attempt}: no saved page URL, using goBack`);
                    await page.goBack({ waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => { });
                    await sleep(rand(SMS_RESEND_WAIT_MS_MIN, SMS_RESEND_WAIT_MS_MAX));
                }
            } else {
                // First attempt: save the recovery options page URL for later navigation
                smsPageUrl = page.url();
                debug(`Recovery options page URL saved: ${smsPageUrl}`);
            }

            const sent = await trySMSAndContinue(page, number);
            if (sent) {
                successCount++;
                debug(`OTP send #${attempt} confirmed ✓`);
                await saveScreenshot(page, number, 'success', `otp_sent_${attempt}`);

                // Stay on OTP screen for 5-7s before going back for next resend
                if (attempt < SMS_RESEND_COUNT) {
                    const stayMs = rand(SMS_RESEND_WAIT_MS_MIN, SMS_RESEND_WAIT_MS_MAX);
                    debug(`Staying on OTP screen for ${stayMs}ms before resend ${attempt + 1}...`);
                    await sleep(stayMs);
                }
            } else {
                debug(`SMS send attempt ${attempt} failed — stopping resend loop`);
                break;
            }
        }

        if (successCount > 0) {
            debug(`All ${successCount} OTP sends complete. Waiting 5s before closing...`);
            await sleep(5000);
            return { result: 'success', errorMsg: '', sendCount: successCount };
        }

        // No SMS found
        await saveScreenshot(page, number, 'failed', 'no_sms_primary');
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

        const safeDomain = (domain && typeof domain === 'string') ? domain : 'https://mbasic.facebook.com';
        debug(`Processing ${number} with domain: ${safeDomain}`);

        const proxyConfig = proxy ? parseProxy(proxy) : null;
        if (proxy && !proxyConfig) {
            debug(`Invalid proxy format: ${proxy}, falling back to direct`);
        }

        const { result, errorMsg, sendCount } = await processNumber(number, safeDomain, userAgent, proxyConfig, language);
        parentPort.postMessage({
            type: 'result', number, result, errorMsg, language,
            sendCount: sendCount || 0,
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
