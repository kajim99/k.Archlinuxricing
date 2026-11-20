// spotify-keys — custom Spotify shortcuts (2026-11-08, replaces liquid-lyrics-key.js from 2026-11-07).
//   Ctrl+L  presses Liquid Lyrics' player-bar button (Marketplace extension NMWplays/Liquid-Lyrics)
//   Ctrl+K  opens search (Spotify's own Ctrl+L search is blocked)
//   Ctrl+R  reloads the Spotify window so extensions + theme start again (Spotify's Ctrl+R repeat is blocked)
// Also: if Spotify started offline, it reloads once when the network comes back, so Marketplace
// extensions (fetched from GitHub) load without a manual restart.
(function spotifyKeys() {
    if (!Spicetify?.showNotification || !Spicetify.Platform?.History) {
        setTimeout(spotifyKeys, 300);
        return;
    }

    const openSearch = () => {
        Spicetify.Platform.History.push('/search');
        setTimeout(() => document.querySelector('[data-testid="search-input"], input[role="combobox"]')?.focus(), 150);
    };
    const keys = {
        l: () => {
            const button = document.getElementById('liquid-lyrics-button');
            if (button) button.click();
            else Spicetify.showNotification('Liquid Lyrics button not found — is the extension on?');
        },
        k: openSearch,
        r: () => location.reload(),
    };

    // Capture on window runs before Spotify's own shortcut listeners lower in the page.
    const block = e => {
        if (!e.ctrlKey || e.shiftKey || e.altKey || e.metaKey) return null;
        const action = keys[e.key.toLowerCase()];
        if (!action) return null;
        e.preventDefault();
        e.stopImmediatePropagation();
        return action;
    };
    window.addEventListener('keydown', e => {
        const action = block(e);
        if (action && !e.repeat) action();
    }, true);
    window.addEventListener('keypress', block, true);
    window.addEventListener('keyup', block, true);

    // Offline start → one reload when back online (at most once a minute, so it can't loop).
    const startedOffline = !navigator.onLine;
    window.addEventListener('online', () => {
        const missing = startedOffline || !document.getElementById('liquid-lyrics-button');
        const last = Number(sessionStorage.getItem('spotify-keys:reloaded') || 0);
        if (!missing || Date.now() - last < 60000) return;
        sessionStorage.setItem('spotify-keys:reloaded', String(Date.now()));
        setTimeout(() => location.reload(), 2000);
    });
})();
