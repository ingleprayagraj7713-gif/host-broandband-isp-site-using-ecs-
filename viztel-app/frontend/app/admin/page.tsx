import Link from 'next/link';

const stats = [
  { label: 'Active subscribers', value: '14,250' },
  { label: 'Monthly revenue', value: '₹48.2L' },
  { label: 'Open tickets', value: '231' },
  { label: 'Network uptime', value: '99.98%' },
];

export default function AdminPage() {
  return (
    <main className="page-shell detail-page">
      <header className="topbar compact-topbar">
        <div className="brand-block">
          <span className="brand-mark">V</span>
          <span>Viztel Fiber</span>
        </div>
        <nav className="nav" aria-label="Admin navigation">
          <Link href="/">Home</Link>
          <Link href="/portal">Portal</Link>
        </nav>
      </header>

      <section className="section-block">
        <p className="eyebrow">Admin dashboard</p>
        <h1>Operations overview</h1>
        <div className="stats-row">
          {stats.map((stat) => (
            <div key={stat.label} className="stat-box">
              <strong>{stat.value}</strong>
              <span>{stat.label}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="portal-grid">
        <div className="feature-card">
          <h3>Plan performance</h3>
          <p>Fiber 500 is leading new activations this month.</p>
        </div>
        <div className="feature-card">
          <h3>Field issues</h3>
          <p>2 unresolved last-mile incidents in East Zone.</p>
        </div>
        <div className="feature-card">
          <h3>Payment health</h3>
          <p>98.4% of invoices successfully processed.</p>
        </div>
      </section>
    </main>
  );
}
