// cover-colors — Spotify takes its colors from the playing song's album cover (2026-11-07).
// Accents + a dark tint of the background, always pushed dark & saturated; fades ~0.6s.
// Profile menu → "Cover colors" turns it on/off; off (or a gray/missing cover) = plain VioletNeon.
(function coverColors() {
    if (!Spicetify?.Player?.addEventListener || !Spicetify.colorExtractor || !Spicetify.Menu || !Spicetify.LocalStorage) {
        setTimeout(coverColors, 300);
        return;
    }

    const KEY = 'cover-colors:on';
    const root = document.documentElement;
    const SPICE = ['main', 'main-elevated', 'highlight', 'highlight-elevated', 'sidebar', 'player', 'card',
        'button', 'button-active', 'button-secondary', 'tab-active', 'equalizer', 'notification', 'text', 'subtext'];
    const VN = ['a', 'a2', 'b', 'sel', 'track', 'scroll', 'panel', 'card', 'menu'];

    // Spotify's own --spice-* colors, registered as colors so they fade like the --vn-* ones in user.css.
    const cs = getComputedStyle(root);
    for (const n of SPICE) {
        const v = cs.getPropertyValue(`--spice-${n}`).trim();
        try { CSS.registerProperty({ name: `--spice-${n}`, syntax: '<color>', inherits: true, initialValue: v || '#000000' }); } catch (e) {}
    }
    root.style.transition = [...SPICE.map(n => `--spice-${n}`), ...VN.map(n => `--vn-${n}`)]
        .map(p => `${p} .6s ease`).join(', ');

    const toHsl = hex => {
        const m = /^#?([0-9a-f]{6})$/i.exec(String(hex || '').trim());
        if (!m) return null;
        const i = parseInt(m[1], 16), r = (i >> 16) / 255, g = (i >> 8 & 255) / 255, b = (i & 255) / 255;
        const max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2, d = max - min;
        if (!d) return { h: 0, s: 0, l };
        const s = d / (1 - Math.abs(2 * l - 1));
        const h = max === r ? ((g - b) / d + 6) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
        return { h: h * 60, s, l };
    };
    const toRgb = (h, s, l) => {
        const k = n => (n + h / 30) % 12, a = s * Math.min(l, 1 - l);
        return [0, 8, 4].map(n => Math.round(255 * (l - a * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1)))));
    };
    const hex = rgb => '#' + rgb.map(v => v.toString(16).padStart(2, '0')).join('');
    const lum = rgb => rgb.map(v => v / 255).map(v => v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4)
        .reduce((t, v, i) => t + v * [0.2126, 0.7152, 0.0722][i], 0);
    // A neon accent no brighter than ~0.3 luminance, so yellows/greens/cyans stay deep like #8703ff.
    const neon = (h, l) => {
        let rgb = toRgb(h, 1, l);
        while (lum(rgb) > 0.3 && l > 0.3) rgb = toRgb(h, 1, l -= 0.02);
        return rgb;
    };
    const hueGap = (x, y) => Math.min(Math.abs(x - y), 360 - Math.abs(x - y));

    const keys = [];
    const put = (name, rgb) => {
        root.style.setProperty(`--${name}`, hex(rgb));
        if (name.startsWith('spice-')) root.style.setProperty(`--spice-rgb-${name.slice(6)}`, rgb.join(','));
        keys.push(name);
    };
    const reset = () => {
        for (const name of keys.splice(0)) {
            root.style.removeProperty(`--${name}`);
            if (name.startsWith('spice-')) root.style.removeProperty(`--spice-rgb-${name.slice(6)}`);
        }
    };

    const paint = c => {
        const swatches = [c.VIBRANT, c.VIBRANT_NON_ALARMING, c.PROMINENT, c.DARK_VIBRANT, c.LIGHT_VIBRANT, c.DESATURATED]
            .map(toHsl).filter(x => x && x.s > 0.12);
        if (!swatches.length) return reset();
        const h = swatches[0].h;
        // Second color: the cover's most different hue, else the same step violet → blue takes.
        const other = swatches.slice(1).sort((x, y) => hueGap(y.h, h) - hueGap(x.h, h))[0];
        const h2 = other && hueGap(other.h, h) >= 30 ? other.h : (h + 305) % 360;

        const a = neon(h, 0.5), a2 = neon(h, 0.57), b = neon(h2, 0.45), sel = toRgb(h, 1, 0.28);
        const bg = l => toRgb(h, 0.42, l);
        reset();
        put('vn-a', a); put('vn-a2', a2); put('vn-b', b); put('vn-sel', sel);
        put('vn-track', bg(0.22)); put('vn-scroll', toRgb(h, 0.3, 0.32));
        put('vn-panel', bg(0.14)); put('vn-card', bg(0.22)); put('vn-menu', bg(0.10));
        put('spice-main', bg(0.10)); put('spice-main-elevated', bg(0.14));
        put('spice-highlight', bg(0.18)); put('spice-highlight-elevated', bg(0.22));
        put('spice-sidebar', bg(0.08)); put('spice-player', bg(0.08)); put('spice-card', bg(0.14));
        put('spice-button', a); put('spice-button-active', a2); put('spice-button-secondary', b);
        put('spice-tab-active', sel); put('spice-equalizer', a); put('spice-notification', b);
        put('spice-text', toRgb(h, 1, 0.93)); put('spice-subtext', toRgb(h, 0.32, 0.70));
    };

    const on = () => Spicetify.LocalStorage.get(KEY) !== '0';
    let turn = 0;
    const update = async () => {
        const mine = ++turn;
        const uri = Spicetify.Player.data?.item?.uri;
        if (!on() || !uri) return reset();
        try {
            const colors = await Spicetify.colorExtractor(uri);
            if (mine === turn) colors ? paint(colors) : reset();
        } catch (e) {
            if (mine === turn) reset();
        }
    };

    new Spicetify.Menu.Item('Cover colors', on(), self => {
        Spicetify.LocalStorage.set(KEY, on() ? '0' : '1');
        self.setState(on());
        update();
    }).register();

    Spicetify.Player.addEventListener('songchange', update);
    update();
})();
