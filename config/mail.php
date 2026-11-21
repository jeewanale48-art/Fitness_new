<?php
declare(strict_types=1);
// Configure these values locally. Never commit real SMTP credentials.
return [
    'host' => 'smtp.gmail.com',
    'port' => 587,
    'username' => 'YOUR_GMAIL_ADDRESS@gmail.com',
    'password' => 'YOUR_GOOGLE_APP_PASSWORD',
    'encryption' => 'tls',
    'from_email' => 'YOUR_GMAIL_ADDRESS@gmail.com',
    'from_name' => 'FitTrack',
    'enabled' => false,
];
