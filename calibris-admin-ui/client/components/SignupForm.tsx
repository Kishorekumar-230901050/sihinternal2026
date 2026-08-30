import React from 'react';
import { Box, TextField, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

export default function SignupForm() {
  const navigate = useNavigate();
  const [name, setName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [loading, setLoading] = React.useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Placeholder: call POST /api/auth/signup
      await new Promise((res) => setTimeout(res, 800));
      navigate('/auth/verify-otp');
    } catch (err) {
      console.error(err);
    } finally { setLoading(false); }
  };

  return (
    <Box component="form" onSubmit={submit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <TextField label="Full name" value={name} onChange={(e) => setName(e.target.value)} size="small" required />
      <TextField label="Email" value={email} onChange={(e) => setEmail(e.target.value)} size="small" required />
      <TextField label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} size="small" required />
      <Button type="submit" variant="contained" disabled={loading}>Create account</Button>
    </Box>
  );
}
