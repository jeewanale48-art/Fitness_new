<?php
require_once __DIR__.'/../includes/auth.php';requireAdmin();
$id=(int)($_GET['id']??0);$q=$pdo->prepare('SELECT proof_file FROM subscription_requests WHERE id=?');$q->execute([$id]);$r=$q->fetch();
if(!$r||empty($r['proof_file'])){http_response_code(404);exit('Payment proof not found.');}
$name=basename($r['proof_file']);$path=__DIR__.'/../uploads/payment-proofs/'.$name;
if(!is_file($path)){http_response_code(404);exit('Payment proof file is missing.');}
$finfo=new finfo(FILEINFO_MIME_TYPE);$mime=$finfo->file($path);$allowed=['image/jpeg','image/png','application/pdf'];if(!in_array($mime,$allowed,true)){http_response_code(415);exit('Unsupported file type.');}
header('X-Content-Type-Options: nosniff');header("Content-Security-Policy: default-src 'none'; sandbox");header('Content-Type: '.$mime);header('Content-Length: '.filesize($path));header('Content-Disposition: inline; filename="payment-proof-'.$id.'"');readfile($path);exit;
