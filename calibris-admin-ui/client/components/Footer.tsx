import React from "react";

const Footer: React.FC = () => (
  <footer className="gov-footer">
    <div>
      <strong>Department of Legal Metrology</strong> · भारत सरकार / Government of India
    </div>
    <div style={{ marginTop: 4, opacity: 0.7 }}>
      © {new Date().getFullYear()} Calibris. All rights reserved.
    </div>
  </footer>
);

export default Footer;
