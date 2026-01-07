import React, { useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE || "/api";

export default function App() {
  const [url, setUrl] = useState("");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");

  const analyze = async () => {
    if (!url.trim()) return;
    setLoading(true);
    setError("");
    setResult(null);
    try {
      const res = await fetch(`${API_BASE}/predict`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setResult(data);
    } catch (e) {
      setError(String(e.message || e));
    } finally {
      setLoading(false);
    }
  };

  const label = result?.prediction || result?.label || result?.result;
  const score = result?.probability || result?.score || result?.confidence;
  const isSafe = label ? ["safe", "benign", "clean"].includes(String(label).toLowerCase()) : null;

  return (
    <div className="app-shell">
      <header className="hero">
        <div className="logo">🔎</div>
        <h1 className="title">URL Detector</h1>
        <p className="subtitle">Paste a URL and get a quick risk assessment.</p>
      </header>

      <section className="card glass">
        <div className="input-row">
          <input
            className="input"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://example.com/path"
            aria-label="URL to analyze"
          />
          <button
            className={`btn ${loading ? "loading" : ""}`}
            onClick={analyze}
            disabled={!url.trim() || loading}
          >
            {loading ? <span className="spinner" aria-hidden /> : "Analyze"}
          </button>
        </div>

        <div className="links">
          <a className="link" href="/api/docs" target="_blank" rel="noreferrer">
            Open API Docs
          </a>
        </div>
      </section>

      {error && (
        <section className="card error-card" role="alert">
          <strong>Backend error:</strong> {error}
        </section>
      )}

      {result && (
        <section className="card result-card">
          <div className="result-header">
            <span className={`badge ${isSafe ? "badge-safe" : "badge-danger"}`}>
              {isSafe ? "Safe" : "Suspicious"}
            </span>
            <h3 className="result-title">{label ?? "Result"}</h3>
          </div>

          {typeof score !== "undefined" ? (
            <div className="progress">
              <div
                className="progress-bar"
                style={{ width: `${Math.max(0, Math.min(1, Number(score))) * 100}%` }}
              />
              <div className="progress-label">
                Confidence: {Number(score).toLocaleString(undefined, { style: "percent", minimumFractionDigits: 0 })}
              </div>
            </div>
          ) : (
            <pre className="json">{JSON.stringify(result, null, 2)}</pre>
          )}

          <footer className="footer">
            <small>API: {API_BASE}/predict</small>
          </footer>
        </section>
      )}
    </div>
  );
}
