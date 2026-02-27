// Simple NUI handler for Oublitix overlay/text
function toggleOublitixOverlay(visible) {
    const overlay = document.getElementById('oublitix-overlay');
    if (!overlay) return;
    overlay.classList.toggle('visible', !!visible);
}

function toggleOublitixText(visible, message) {
    const text = document.getElementById('oublitix-text');
    if (!text) return;
    if (message) {
        text.textContent = message;
    }
    text.classList.toggle('visible', !!visible);
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'showOublitixOverlay') {
        console.log('[dvr_oublitix][NUI] overlay ->', data.visible);
        toggleOublitixOverlay(data.visible);
    } else if (data.action === 'showOublitixText') {
        console.log('[dvr_oublitix][NUI] text ->', data.visible, 'msg:', data.message);
        toggleOublitixText(data.visible, data.message);
    }
});

