import React from 'react';
import { Box, Card, CardContent, Typography } from '@mui/material';
import OtpForm from '@/components/OtpForm';

export default function VerifyOtpPage() {
  return (
    <Box sx={{ minHeight: 'calc(100vh - 64px)', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--bg)', p: 2 }}>
      <Card sx={{ width: 420, bgcolor: 'var(--panel)', color: 'var(--text)', borderRadius: '12px' }}>
        <CardContent>
          <Typography variant="h5" sx={{ mb: 2 }}>Verify your email</Typography>
          <OtpForm />
        </CardContent>
      </Card>
    </Box>
  );
}
