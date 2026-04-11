import React from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { Home, ScanLine, FlaskConical, Monitor } from 'lucide-react';
import { motion } from 'framer-motion';

const navItems = [
  { path: '/', icon: Home, label: 'Receipts' },
  { path: '/scan', icon: ScanLine, label: 'Scan' },
  { path: '/test-qr', icon: FlaskConical, label: 'Test QR' },
  { path: '/kiosk', icon: Monitor, label: 'Kiosk' },
];

export default function AppShell() {
  const location = useLocation();

  return (
    <div className="h-screen bg-background flex flex-col overflow-hidden">
      <main className="flex-1 overflow-y-auto pb-24">
        <Outlet />
      </main>

      {/* iOS-style tab bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-50">
        <div className="bg-card/80 backdrop-blur-xl border-t border-border">
          <div className="max-w-lg mx-auto flex items-center justify-around px-4 py-2 pb-6">
            {navItems.map(({ path, icon: Icon, label }) => {
              const isActive = location.pathname === path;
              return (
                <Link
                  key={path}
                  to={path}
                  className="flex flex-col items-center gap-0.5 py-1 px-4 relative"
                >
                  {isActive && (
                    <motion.div
                      layoutId="tab-indicator"
                      className="absolute -top-2 w-6 h-0.5 bg-primary rounded-full"
                      transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                    />
                  )}
                  <Icon
                    className={`w-5 h-5 transition-colors ${
                      isActive ? 'text-primary' : 'text-muted-foreground'
                    }`}
                    strokeWidth={isActive ? 2.2 : 1.8}
                  />
                  <span
                    className={`text-[10px] font-medium tracking-wide transition-colors ${
                      isActive ? 'text-primary' : 'text-muted-foreground'
                    }`}
                  >
                    {label}
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </nav>
    </div>
  );
}