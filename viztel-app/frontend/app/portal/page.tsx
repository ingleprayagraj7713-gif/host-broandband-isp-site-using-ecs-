import Link from 'next/link';

const usageData = [
  { label: 'Current Plan', value: 'Fiber 500' },
  { label: 'Internet Speed', value: '495 Mbps' },
  { label: 'Account Status', value: 'Active' },
  { label: 'Next Billing', value: '15 Dec 2026' },
];

export default function PortalPage() {
  return (
    <main className="page-shell detail-page">
      <header className="topbar compact-topbar">
        <div className="brand-block">
          <span className="brand-mark">V</span>
          <span>Viztel Fiber</span>
        </div>
        <nav className="nav" aria-label="Portal navigation">
          <Link href="/">Home</Link>
          <Link href="/admin">Admin</Link>
        </nav>
      </header>

      <section className="section-block">
        <p className="eyebrow">Customer portal</p>
        <h1>Welcome back, Aanya.</h1>
        <div className="stats-row">
          {usageData.map((item) => (
            <div key={item.label} className="stat-box">
              <strong>{item.value}</strong>
              <span>{item.label}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="portal-grid">
        <div className="feature-card">
          <h3>Billing</h3>
          <p>Due amount: ₹999</p>
          <button className="primary-btn">Pay now</button>
        </div>
        <div className="feature-card">
          <h3>Service usage</h3>
          <p>Peak hours usage: 68% of network capacity</p>
        </div>
        <div className="feature-card">
          <h3>Support</h3>
          <p>Last support ticket resolved in 2 hours</p>
        </div>
      </section>
    </main>
  );
}
