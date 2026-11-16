import Link from 'next/link';

const plans = [
  {
    name: 'Fiber 200',
    price: '₹699',
    speed: '200 Mbps',
    description: 'Perfect for streaming and work from home',
  },
  {
    name: 'Fiber 500',
    price: '₹999',
    speed: '500 Mbps',
    description: 'Best for homes with multiple users and 4K streaming',
  },
  {
    name: 'Fiber 1G',
    price: '₹1,499',
    speed: '1 Gbps',
    description: 'Ultra-fast for gaming, automation, and smart homes',
  },
];

const stats = [
  { label: 'Coverage', value: '15+ cities' },
  { label: 'Avg. latency', value: '<10 ms' },
  { label: 'Customer rating', value: '4.9/5' },
];

export default function HomePage() {
  return (
    <main className="page-shell">
      <header className="topbar">
        <div className="brand-block">
          <span className="brand-mark">V</span>
          <span>Viztel Fiber</span>
        </div>
        <nav className="nav" aria-label="Main navigation">
          <a href="#plans">Plans</a>
          <a href="#features">Why Viztel</a>
          <Link href="/portal">Customer Portal</Link>
          <Link href="/admin">Admin</Link>
        </nav>
        <button className="primary-btn">Get Started</button>
      </header>

      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">Broadband for the next generation</p>
          <h1>Fast, reliable fiber internet built for modern living.</h1>
          <p className="subtext">
            Secure home broadband, uptime-focused support, and seamless online account
            management for every customer.
          </p>
          <div className="cta-row">
            <button className="primary-btn">Choose a Plan</button>
            <button className="secondary-btn">Talk to Sales</button>
          </div>
          <div className="stats-row">
            {stats.map((stat) => (
              <div key={stat.label} className="stat-box">
                <strong>{stat.value}</strong>
                <span>{stat.label}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="hero-panel">
          <div className="panel-card">
            <span className="mini-label">Live network health</span>
            <h3>99.98% uptime</h3>
            <div className="meter">
              <span style={{ width: '92%' }} />
            </div>
            <ul>
              <li>Symmetric upload and download</li>
              <li>24/7 support and monitoring</li>
              <li>Smart Wi‑Fi ready homes</li>
            </ul>
          </div>
        </div>
      </section>

      <section id="plans" className="section-block">
        <div className="section-head">
          <p className="eyebrow">Broadband Plans</p>
          <h2>Choose a plan that fits your lifestyle.</h2>
        </div>
        <div className="plans-grid">
          {plans.map((plan) => (
            <article key={plan.name} className="plan-card">
              <span className="plan-tag">Popular</span>
              <h3>{plan.name}</h3>
              <div className="price-row">
                <strong>{plan.price}</strong>
                <span>/month</span>
              </div>
              <p className="speed">{plan.speed}</p>
              <p>{plan.description}</p>
              <button className="primary-btn full-width">Sign Up</button>
            </article>
          ))}
        </div>
      </section>

      <section id="features" className="feature-grid">
        <div className="feature-card">
          <h3>Customer Login Portal</h3>
          <p>Track usage, pay bills, update plans, and manage your connection from one secure dashboard.</p>
        </div>
        <div className="feature-card">
          <h3>Online Payments</h3>
          <p>Secure subscriptions and invoices with encrypted payment flows and instant confirmations.</p>
        </div>
        <div className="feature-card">
          <h3>Admin Dashboard</h3>
          <p>Monitor active customers, service health, plan distribution, and operational performance.</p>
        </div>
      </section>

      <section id="portal" className="section-block portal-box">
        <div>
          <p className="eyebrow">Portal access</p>
          <h2>Customer and admin tools for everyday operations.</h2>
        </div>
        <div className="portal-actions">
          <Link href="/portal" className="primary-btn">Customer Login</Link>
          <Link href="/admin" className="secondary-btn">Admin Login</Link>
        </div>
      </section>

      <section id="admin" className="section-block admin-panel">
        <div className="section-head">
          <p className="eyebrow">Admin snapshot</p>
          <h2>Operational visibility at a glance.</h2>
        </div>
        <div className="admin-grid">
          <div className="admin-box">
            <span>Active subscribers</span>
            <strong>14,250</strong>
          </div>
          <div className="admin-box">
            <span>Monthly revenue</span>
            <strong>₹48.2L</strong>
          </div>
          <div className="admin-box">
            <span>Open support tickets</span>
            <strong>231</strong>
          </div>
        </div>
      </section>
    </main>
  );
}
