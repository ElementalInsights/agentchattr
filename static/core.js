/**
 * core.js -- EventHub for agentchattr
 *
 * Tiny pub/sub hub. WebSocket events are emitted here so modules can
 * subscribe without touching the legacy switch statement in chat.js.
 *
 * Usage:
 *   Hub.on('session', (data) => { ... });
 *   Hub.emit('session', { action: 'create', data: session });
 *   Hub.off('session', handler);
 */

const Hub = (() => {
    const _listeners = {};

    function on(type, fn) {
        if (!_listeners[type]) _listeners[type] = [];
        _listeners[type].push(fn);
    }

    function off(type, fn) {
        const list = _listeners[type];
        if (!list) return;
        const idx = list.indexOf(fn);
        if (idx !== -1) list.splice(idx, 1);
    }

    function emit(type, data) {
        const list = _listeners[type];
        if (!list) return;
        for (const fn of list) {
            try {
                fn(data);
            } catch (e) {
                console.error(`[Hub] Error in listener for "${type}":`, e);
            }
        }
    }

    return { on, off, emit };
})();

// Make Hub available globally during the transition period.
// Once all modules use ES imports, this can be removed.
window.Hub = Hub;

// --- Right panel tab switcher (shared Jobs/Rules container) ---
function switchRightPanel(tab) {
    const jobsContent = document.getElementById('rp-jobs-content');
    const rulesContent = document.getElementById('rp-rules-content');
    const jobsTab = document.getElementById('rp-tab-jobs');
    const rulesTab = document.getElementById('rp-tab-rules');
    if (!jobsContent || !rulesContent) return;

    if (tab === 'jobs') {
        jobsContent.classList.remove('hidden');
        rulesContent.classList.add('hidden');
        jobsTab.classList.add('active');
        rulesTab.classList.remove('active');
        document.getElementById('jobs-toggle').classList.add('active');
        document.getElementById('rules-toggle').classList.remove('active');
        // Render jobs if switching to it
        if (typeof renderJobsList === 'function') renderJobsList();
    } else {
        rulesContent.classList.remove('hidden');
        jobsContent.classList.add('hidden');
        rulesTab.classList.add('active');
        jobsTab.classList.remove('active');
        document.getElementById('rules-toggle').classList.add('active');
        document.getElementById('jobs-toggle').classList.remove('active');
        // Render rules if switching to it
        if (typeof renderRulesPanel === 'function') renderRulesPanel();
    }
}

window.switchRightPanel = switchRightPanel;

function closeRightPanel() {
    const rightPanel = document.getElementById('right-panel');
    if (rightPanel) rightPanel.classList.add('hidden');
    const jobsToggle = document.getElementById('jobs-toggle');
    const rulesToggle = document.getElementById('rules-toggle');
    if (jobsToggle) jobsToggle.classList.remove('active');
    if (rulesToggle) rulesToggle.classList.remove('active');
}

window.closeRightPanel = closeRightPanel;

function endChatSession() {
    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) return;
    window.ws.send(JSON.stringify({
        type: 'message',
        text: '/stop',
        sender: window.username || 'user',
        channel: window.activeChannel || 'general'
    }));
}

window.endChatSession = endChatSession;
