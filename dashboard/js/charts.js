let responseChart = null;

function initResponseChart() {
  const ctx = document.getElementById("response-chart").getContext("2d");
  responseChart = new Chart(ctx, {
    type: "line",
    data: {
      labels: [],
      datasets: [{
        label: "Response Time (ms)",
        data: [],
        borderColor: "#38bdf8",
        backgroundColor: "rgba(56,189,248,0.1)",
        tension: 0.3,
        fill: true,
        pointRadius: 3,
      }],
    },
    options: {
      responsive: true,
      plugins: { legend: { labels: { color: "#94a3b8" } } },
      scales: {
        x: { ticks: { color: "#64748b" }, grid: { color: "#1e293b" } },
        y: { ticks: { color: "#64748b" }, grid: { color: "#1e293b" } },
      },
    },
  });
}

function updateResponseChart(history) {
  if (!responseChart) initResponseChart();
  const labels = history.map(h => new Date(h.checked_at).toLocaleTimeString()).reverse();
  const data = history.map(h => h.response_time).reverse();
  responseChart.data.labels = labels;
  responseChart.data.datasets[0].data = data;
  responseChart.update();
}
