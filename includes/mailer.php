<?php
declare(strict_types=1);
function fittrackSendMail(string $to, string $subject, string $html): bool {
    $config = require __DIR__ . '/../config/mail.php';
    if (empty($config['enabled'])) { error_log('FitTrack email not sent: configure config/mail.php and enable SMTP.'); return false; }
    $autoload = __DIR__ . '/../vendor/autoload.php';
    if (!is_file($autoload)) { error_log('FitTrack email not sent: run composer install.'); return false; }
    require_once $autoload;
    try {
        $mail = new PHPMailer\PHPMailer\PHPMailer(true);
        $mail->isSMTP(); $mail->Host=$config['host']; $mail->SMTPAuth=true;
        $mail->Username=$config['username']; $mail->Password=$config['password'];
        $mail->SMTPSecure=$config['encryption']; $mail->Port=(int)$config['port'];
        $mail->setFrom($config['from_email'], $config['from_name']); $mail->addAddress($to);
        $mail->isHTML(true); $mail->Subject=$subject; $mail->Body=$html;
        $mail->AltBody=trim(strip_tags(str_replace(['<br>','<br/>','</p>'],"\n",$html)));
        $mail->send(); return true;
    } catch (Throwable $e) { error_log('FitTrack SMTP error: '.$e->getMessage()); return false; }
}
function fittrackNotify(PDO $pdo, int $userId, string $title, string $message, ?string $emailSubject=null): void {
    $q=$pdo->prepare('INSERT INTO notifications (user_id,title,message) VALUES (?,?,?)');
    $q->execute([$userId,$title,$message]);
    if ($emailSubject) {
        $q=$pdo->prepare('SELECT email,name FROM users WHERE id=?'); $q->execute([$userId]); $u=$q->fetch();
        if ($u) {
            $config=require __DIR__.'/../config/mail.php';
            $sent=fittrackSendMail($u['email'],$emailSubject,'<p>Hello '.htmlspecialchars($u['name'],ENT_QUOTES,'UTF-8').',</p><p>'.nl2br(htmlspecialchars($message,ENT_QUOTES,'UTF-8')).'</p><p>FitTrack</p>');
            $status=$sent?'sent':(empty($config['enabled'])?'not_configured':'failed');
            $log=$pdo->prepare('INSERT INTO email_logs(user_id,recipient,subject,status) VALUES(?,?,?,?)');
            $log->execute([$userId,$u['email'],$emailSubject,$status]);
        }
    }
}
