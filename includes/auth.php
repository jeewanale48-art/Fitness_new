<?php
declare(strict_types=1);
require_once __DIR__ . '/init.php';
function requireLogin(): void {
    if (empty($_SESSION['user_id'])) { flash('Please sign in to continue.', 'error'); redirect('login.php'); }
}
function requireRole(string $role): void {
    requireLogin();
    if (($_SESSION['role'] ?? '') !== $role) {
        $inAdmin = str_contains($_SERVER['SCRIPT_NAME'] ?? '', '/admin/');
        if (($_SESSION['role'] ?? '') === 'admin') redirect($inAdmin ? 'dashboard.php' : 'admin/dashboard.php');
        redirect($inAdmin ? '../dashboard.php' : 'dashboard.php');
    }
}
function requireAdmin(): void { requireRole('admin'); }
function signInUser(array $user): void {
    session_regenerate_id(true);
    $_SESSION['user_id']=(int)$user['id']; $_SESSION['user_name']=$user['name'];
    $_SESSION['user_email']=$user['email']; $_SESSION['role']=$user['role'];
}
