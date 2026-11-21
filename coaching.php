<?php
require_once __DIR__ . '/includes/auth.php';
requireRole('user');
$uid = (int) $_SESSION['user_id'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verifyCsrf();
    $coachId = (int) ($_POST['coach_id'] ?? 0);
    $when = str_replace('T', ' ', (string) ($_POST['session_start'] ?? ''));
    $message = trim((string) ($_POST['user_message'] ?? ''));
    $date = DateTime::createFromFormat('Y-m-d H:i', $when);

    $coachQuery = $pdo->prepare('SELECT id FROM coaches WHERE id = ? AND is_active = 1');
    $coachQuery->execute([$coachId]);

    if (!$coachQuery->fetch()) {
        $error = 'Select an available coach.';
    } elseif (!$date || $date < new DateTime('+1 hour')) {
        $error = 'Choose a session at least one hour in the future.';
    } else {
        $weekday = (int) $date->format('N');
        $clock = $date->format('H:i:s');
        $scheduleCountQuery = $pdo->prepare('SELECT COUNT(*) FROM coach_availability WHERE coach_id = ?');
        $scheduleCountQuery->execute([$coachId]);
        $hasSchedule = (int) $scheduleCountQuery->fetchColumn() > 0;

        $available = false;
        if ($hasSchedule) {
            $availabilityQuery = $pdo->prepare('SELECT id FROM coach_availability WHERE coach_id = ? AND weekday = ? AND start_time <= ? AND end_time > ? LIMIT 1');
            $availabilityQuery->execute([$coachId, $weekday, $clock, $clock]);
            $available = (bool) $availabilityQuery->fetch();
        }

        if (!$available) {
            $error = 'That coach is not available at the selected time.';
        } else {
            $conflictQuery = $pdo->prepare("SELECT id FROM coach_bookings WHERE coach_id = ? AND status IN ('pending','approved') AND session_start < DATE_ADD(?, INTERVAL 60 MINUTE) AND DATE_ADD(session_start, INTERVAL duration_minutes MINUTE) > ? LIMIT 1");
            $selectedTime = $date->format('Y-m-d H:i:s');
            $conflictQuery->execute([$coachId, $selectedTime, $selectedTime]);

            if ($conflictQuery->fetch()) {
                $error = 'That time is already requested or booked. Choose another time.';
            } else {
                $insert = $pdo->prepare('INSERT INTO coach_bookings (user_id, coach_id, session_start, user_message) VALUES (?, ?, ?, ?)');
                $insert->execute([$uid, $coachId, $selectedTime, $message ?: null]);
                $bookingId = (int) $pdo->lastInsertId();
                $pdo->prepare('INSERT INTO admin_notifications (title, message, related_type, related_id) VALUES (?, ?, ?, ?)')
                    ->execute(['New coaching request', $_SESSION['user_name'] . ' requested a coaching session.', 'booking', $bookingId]);
                flash('Coaching request submitted for admin approval.');
                redirect('coaching.php');
            }
        }
    }
}

$coaches = $pdo->query('SELECT c.*, (SELECT COUNT(*) FROM coach_availability a WHERE a.coach_id = c.id) availability_count FROM coaches c WHERE c.is_active = 1 ORDER BY c.name')->fetchAll();
$bookingQuery = $pdo->prepare('SELECT b.*, c.name coach_name, c.specialization FROM coach_bookings b JOIN coaches c ON c.id = b.coach_id WHERE b.user_id = ? ORDER BY b.session_start DESC');
$bookingQuery->execute([$uid]);
$bookings = $bookingQuery->fetchAll();
$pageTitle = 'Coaching';
require __DIR__ . '/includes/header.php';
?>
<section class="page-heading"><div><p class="eyebrow">PERSONAL SUPPORT</p><h1>Find your coach</h1><p>Explore available coaches and request a session. The FitTrack admin team confirms bookings.</p></div></section>
<?php if ($error): ?><div class="alert error"><?= e($error) ?></div><?php endif; ?>
<div class="coach-grid">
<?php foreach ($coaches as $coach): ?>
<article class="panel coach-card">
    <div class="coach-avatar"><?= e(strtoupper(substr($coach['name'], 0, 1))) ?></div>
    <h3><?= e($coach['name']) ?></h3>
    <p><strong><?= e($coach['specialization']) ?></strong></p>
    <p><?= nl2br(e($coach['bio'] ?? '')) ?></p>
    <p class="muted"><?= e((string) ($coach['experience_years'] ?? 'Not specified')) ?> years experience · <?= e($coach['fee'] === null ? 'Fee on request' : number_format((float) $coach['fee'], 2)) ?></p>
    <p class="muted"><?= (int) $coach['availability_count'] > 0 ? 'Weekly availability configured' : 'Schedule to be confirmed by admin' ?></p>
    <form method="post">
        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
        <input type="hidden" name="coach_id" value="<?= (int) $coach['id'] ?>">
        <label>Requested date and time</label><input type="datetime-local" name="session_start" required>
        <label>Message (optional)</label><textarea name="user_message" rows="2"></textarea>
        <button class="button full">Request session</button>
    </form>
</article>
<?php endforeach; ?>
</div>
<section class="panel"><h2>Your coaching requests</h2>
<?php if (!$bookings): ?><p>No coaching bookings yet.</p><?php else: ?>
<div class="table-wrap"><table><thead><tr><th>Coach</th><th>Specialization</th><th>Session</th><th>Status</th><th>Admin note</th></tr></thead><tbody>
<?php foreach ($bookings as $booking): ?><tr><td><?= e($booking['coach_name']) ?></td><td><?= e($booking['specialization']) ?></td><td><?= e($booking['session_start']) ?></td><td><?= e(ucfirst($booking['status'])) ?></td><td><?= e($booking['admin_message'] ?? '—') ?></td></tr><?php endforeach; ?>
</tbody></table></div><?php endif; ?></section>
<?php require __DIR__ . '/includes/footer.php'; ?>
