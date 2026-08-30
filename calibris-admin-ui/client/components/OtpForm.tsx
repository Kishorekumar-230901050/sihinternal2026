import React from 'react';
import { Box, TextField, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

export default function OtpForm() {
  const navigate = useNavigate();
  const [otp, setOtp] = React.useState('');
  const [loading, setLoading] = React.useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Placeholder: call POST /api/auth/verify-otp
      await new Promise((res) => setTimeout(res, 800));
      navigate('/');
    } catch (err) {
      console.error(err);
    } finally { setLoading(false); }
  };

  return (
    <Box component="form" onSubmit={submit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <TextField label="Enter OTP" value={otp} onChange={(e) => setOtp(e.target.value)} size="small" required />
      <Button type="submit" variant="contained" disabled={loading}>Verify</Button>
    </Box>
  );
}
