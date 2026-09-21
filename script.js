const state = { coins: 0, level: 1, claimedDays: [], achievements: [], dailyDay: 1, dailyClaimed: false, isAdmin: false };
const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "bergischland_event_pass";
const rewards = [["Werkzeug", "Mechaniker-Kit", "Ingame-Gegenstand"], ["Ticket", "Event-Ticket", "Event-Zugang"], ["Badge", "Diamant-Badge", "Kosmetik"], ["Auto", "Fahrzeug-Token", "Ingame-Recht"], ["Outfit", "Event-Outfit", "Kosmetik"], ["Pokal", "Trophäe", "Profil-Badge"], ["Lack", "Lackierung", "Fahrzeug-Kosmetik"], ["Coins", "+250 Coins", "Event-Coins"], ["Kiste", "Mystery-Kiste", "Ingame-Gegenstand"], ["Titel", "Event-Titel", "Titel"]];
const dailyRewards = [50, 75, 100, 125, 150, 175, 250, 75, 100, 125, 150, 175, 200, 300];
const achievementData = [["Start", "Erste Schritte", "Nimm an deinem ersten Event teil.", 1], ["Rennen", "Event-Raser", "Absolviere 5 Event-Aktivitäten.", 5], ["Coin", "Coin-Sammler", "Verdiene 1.000 Event-Coins.", 1000], ["Ziel", "Treffsicher", "Schließe 10 Event-Missionen ab.", 10], ["Team", "Community", "Spiele gemeinsam mit 5 Spielern.", 5], ["Streak", "Streak", "Hole 7 Tagesbelohnungen ab.", 7], ["Halbzeit", "Halbzeit", "Erreiche Event-Pass Stufe 25.", 25], ["Legende", "Bergischland-Legende", "Erreiche Event-Pass Stufe 50.", 50]];

function fmt(value) { return Number(value || 0).toLocaleString("de-DE"); }
function cost(level) { return 100 + (level - 1) * 25; }
function post(action, data = {}) { if (typeof GetParentResourceName !== "function") return Promise.resolve(); return fetch(`https://${resourceName}/${action}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data) }); }
function toast(message) { const element = document.getElementById("toast"); element.textContent = message; element.classList.add("show"); clearTimeout(window.toastTimer); window.toastTimer = setTimeout(() => element.classList.remove("show"), 2200); }
function renderPass() {
  const element = document.getElementById("passTrack"); element.innerHTML = "";
  for (let level = 1; level <= 50; level += 1) {
    const unlocked = level < state.level, available = level === state.level, reward = rewards[(level - 1) % rewards.length];
    const card = document.createElement("div"); card.className = `pass-card ${unlocked ? "unlocked" : available ? "available" : "locked"}`;
    card.innerHTML = `<span class="pass-num">${level}</span><span class="cost">${fmt(cost(level))} Coins</span><div class="reward-art">${reward[0]}</div><div class="reward-name">${reward[1]}</div><div class="reward-desc">${reward[2]}</div><button class="unlock" ${available ? "" : "disabled"}>${unlocked ? "✓ FREIGESCHALTET" : available ? "STUFE FREISCHALTEN" : "GESPERRT"}</button>`;
    if (available) card.querySelector("button").onclick = () => post("unlockLevel", { level }); element.appendChild(card);
  }
}
function renderDaily() {
  const element = document.getElementById("dailyGrid"); element.innerHTML = "";
  dailyRewards.forEach((reward, index) => { const day = index + 1, claimed = state.claimedDays.includes(day), today = day === state.dailyDay; const card = document.createElement("div"); card.className = `daily-card ${claimed ? "claimed" : ""} ${today ? "today" : ""}`; card.innerHTML = `<div class="daily-day">TAG ${day}</div><div class="daily-icon">${claimed ? "✓" : "Coins"}</div><div class="daily-reward">${claimed ? "ABGEHOLT" : `+${reward} COINS`}</div>${today && !claimed ? '<button>BELOHNUNG ABHOLEN</button>' : ""}`; if (today && !claimed) card.querySelector("button").onclick = () => post("claimDaily"); element.appendChild(card); });
  document.querySelector(".streak").textContent = `Streak: ${Math.max(0, state.dailyDay - 1)} Tage`;
}
function renderAchievements() {
  const element = document.getElementById("achievementGrid"); element.innerHTML = "";
  achievementData.forEach((achievement, index) => { const done = state.achievements.includes(index + 1), value = done ? achievement[3] : 0, percent = done ? 100 : 0; const card = document.createElement("div"); card.className = `achievement ${done ? "done" : ""}`; card.innerHTML = `<div class="ach-icon">${achievement[0]}</div><div style="flex:1"><b>${achievement[1]}</b><small>${achievement[2]}</small><div class="ach-progress"><i style="width:${percent}%"></i></div><small>${value} / ${achievement[3]}</small></div>`; element.appendChild(card); });
}
function render() { document.getElementById("coinBalance").textContent = fmt(state.coins); document.getElementById("overviewCoins").textContent = fmt(state.coins); document.getElementById("currentLevel").textContent = Math.min(state.level, 50); document.getElementById("overviewLevel").textContent = `${Math.min(state.level, 50)} / 50`; document.getElementById("overviewProgress").style.width = `${Math.min(100, (state.level - 1) / 49 * 100)}%`; document.getElementById("nextCost").textContent = state.level <= 50 ? `${fmt(cost(state.level))} Coins` : "Abgeschlossen"; renderPass(); renderDaily(); renderAchievements(); }
function showTab(id) { document.querySelectorAll(".tab-panel").forEach(panel => panel.classList.toggle("active", panel.id === id)); document.querySelectorAll(".nav-item").forEach(button => button.classList.toggle("active", button.dataset.tab === id)); }
document.querySelectorAll(".nav-item").forEach(button => { button.onclick = () => showTab(button.dataset.tab); }); document.querySelectorAll("[data-tab-target]").forEach(button => { button.onclick = () => showTab(button.dataset.tabTarget); });
window.addEventListener("message", event => { const message = event.data || {}; if (message.action === "open") { document.body.classList.add("visible"); state.isAdmin = !!message.isAdmin; render(); } if (message.action === "close") document.body.classList.remove("visible"); if (message.action === "state") { Object.assign(state, message.state || {}); document.body.classList.add("visible"); render(); } if (message.action === "toast") toast(message.message || ""); });
document.addEventListener("keydown", event => { if (event.key === "Escape") post("close"); }); render();
