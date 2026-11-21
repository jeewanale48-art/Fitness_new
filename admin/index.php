<?php require_once __DIR__.'/../includes/init.php'; redirect(!empty($_SESSION['user_id']) && ($_SESSION['role']??'')==='admin' ? 'dashboard.php' : 'login.php');
