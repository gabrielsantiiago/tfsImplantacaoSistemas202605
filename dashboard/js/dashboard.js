const API = window.API_URL || "http://localhost:5000";

async function fetchJSON(path) {
  const res = await fetch(API + path);
  return res.json();
}

function badge(status) {
  return `<span class="badge ${status}">${status}</span>`;
}

function fmt(ts) {
  return ts ? new Date(ts).toLocaleString("pt-BR") : "—";
}

async function loadStats() {
  const s = await fetchJSON("/api/stats");
  document.getElementById("stats").innerHTML = `
    <div class="stat-card healthy"><div class="value">${s.healthy_services}</div><div class="label">Saudáveis</div></div>
    <div class="stat-card unhealthy"><div class="value">${s.unhealthy_services}</div><div class="label">Com Falha</div></div>
    <div class="stat-card warning"><div class="value">${s.open_alerts}</div><div class="label">Alertas Abertos</div></div>
    <div class="stat-card info"><div class="value">${s.avg_response_time_ms}ms</div><div class="label">Resp. Média (1h)</div></div>
  `;
}

async function loadServices() {
  const services = await fetchJSON("/api/services");
  const tbody = document.querySelector("#services-table tbody");
  tbody.innerHTML = services.map(s => `
    <tr style="cursor:pointer" onclick="loadHistory(${s.id})">
      <td>${s.name}</td>
      <td>${s.type}</td>
      <td>${badge(s.last_status || "unknown")}</td>
      <td>${fmt(s.updated_at)}</td>
    </tr>
  `).join("");
}

async function loadHistory(serviceId) {
  const history = await fetchJSON(`/api/services/${serviceId}/history?limit=20`);
  updateResponseChart(history);
}

async function loadAlerts() {
  const alerts = await fetchJSON("/api/alerts");
  const tbody = document.querySelector("#alerts-table tbody");
  if (!alerts.length) {
    tbody.innerHTML = `<tr><td colspan="5" style="color:#64748b;text-align:center">Nenhum alerta ativo</td></tr>`;
    return;
  }
  tbody.innerHTML = alerts.map(a => `
    <tr>
      <td>${a.service_name}</td>
      <td>${badge(a.severity)}</td>
      <td>${a.message}</td>
      <td>${fmt(a.created_at)}</td>
      <td><button class="resolve-btn" onclick="resolveAlert(${a.id})">Resolver</button></td>
    </tr>
  `).join("");
}

async function resolveAlert(id) {
  await fetch(`${API}/api/alerts/${id}/resolve`, { method: "POST" });
  loadAlerts();
  loadStats();
}

async function refresh() {
  await Promise.all([loadStats(), loadServices(), loadAlerts()]);
  document.getElementById("last-update").textContent = "Atualizado: " + new Date().toLocaleTimeString("pt-BR");
}

initResponseChart();
refresh();
setInterval(refresh, 15000);
