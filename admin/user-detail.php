<?php
require_once __DIR__ . '/../includes/auth.php';
requireAdmin();
require_once __DIR__ . '/../includes/mailer.php';

$userId = (int) ($_GET['id'] ?? 0);
$userQuery = $pdo->prepare("SELECT * FROM users WHERE id = ? AND role = 'user'");
$userQuery->execute([$userId]);
$user = $userQuery->fetch();
if (!$user) { http_response_code(404); exit('User not found.'); }
$error = '';

$memberLevel = $user['fitness_level'] === 'advanced' ? 'expert' : $user['fitness_level'];
$isPremium = ($user['subscription_status'] === 'active' && !empty($user['subscription_expires_at']) && $user['subscription_expires_at'] >= date('Y-m-d'));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verifyCsrf();
    $action = $_POST['action'] ?? 'suggest';

    if ($action === 'assign') {
        $dietId = (int) ($_POST['diet_plan_id'] ?? 0);
        $workoutId = (int) ($_POST['workout_template_id'] ?? 0);
        $note = trim((string) ($_POST['assignment_note'] ?? ''));
        $valid = ($dietId > 0 || $workoutId > 0);

        if ($dietId > 0) {
            $check = $pdo->prepare("SELECT id FROM diet_plans WHERE id = ? AND fitness_level = ? AND is_active = 1 AND (access_type = 'free' OR ? = 1)");
            $check->execute([$dietId, $memberLevel, (int) $isPremium]);
            $valid = $valid && (bool) $check->fetch();
        }
        if ($workoutId > 0) {
            $check = $pdo->prepare("SELECT id FROM workout_templates WHERE id = ? AND fitness_level = ? AND is_active = 1 AND (access_type = 'free' OR ? = 1)");
            $check->execute([$workoutId, $memberLevel, (int) $isPremium]);
            $valid = $valid && (bool) $check->fetch();
        }

        if (!$valid) {
            $error = 'Choose at least one valid plan matching the member level and membership.';
        } else {
            $insert = $pdo->prepare('INSERT INTO user_plan_assignments (user_id, diet_plan_id, workout_template_id, assigned_by, notes, starts_on) VALUES (?, ?, ?, ?, ?, CURDATE())');
            $insert->execute([$userId, $dietId ?: null, $workoutId ?: null, $_SESSION['user_id'], $note ?: null]);
            fittrackNotify($pdo, $userId, 'New plan assigned', 'An administrator assigned a new fitness plan to your account.', 'A new FitTrack plan was assigned');
            flash('Plan assigned to user.');
            redirect('user-detail.php?id=' . $userId);
        }
    } else {
        $title = trim((string) ($_POST['title'] ?? ''));
        $suggestion = trim((string) ($_POST['suggestion'] ?? ''));
        $level = $_POST['fitness_level'] ?? $user['fitness_level'];
        if ($title === '' || $suggestion === '') {
            $error = 'Enter a suggestion title and message.';
        } elseif (!in_array($level, ['beginner', 'intermediate', 'expert', 'advanced'], true)) {
            $error = 'Choose a valid fitness level.';
        } else {
            $pdo->prepare('UPDATE users SET fitness_level = ? WHERE id = ?')->execute([$level, $userId]);
            $pdo->prepare('INSERT INTO admin_suggestions (user_id, admin_id, title, suggestion) VALUES (?, ?, ?, ?)')->execute([$userId, $_SESSION['user_id'], $title, $suggestion]);
            fittrackNotify($pdo, $userId, 'New personal suggestion', $title . ': ' . $suggestion, 'A new FitTrack suggestion is available');
            flash('Profile updated and suggestion sent.');
            redirect('user-detail.php?id=' . $userId);
        }
    }
}

$planAccessSql = $isPremium ? '' : " AND access_type = 'free'";
$dietOptionsQuery = $pdo->prepare('SELECT id, title, fitness_level, access_type FROM diet_plans WHERE is_active = 1 AND fitness_level = ?' . $planAccessSql . ' ORDER BY title');
$dietOptionsQuery->execute([$memberLevel]);
$dietOptions = $dietOptionsQuery->fetchAll();
$workoutOptionsQuery = $pdo->prepare('SELECT id, title, fitness_level, access_type FROM workout_templates WHERE is_active = 1 AND fitness_level = ?' . $planAccessSql . ' ORDER BY title');
$workoutOptionsQuery->execute([$memberLevel]);
$workoutOptions = $workoutOptionsQuery->fetchAll();

$assignmentQuery = $pdo->prepare('SELECT a.*, d.title diet_title, w.title workout_title FROM user_plan_assignments a LEFT JOIN diet_plans d ON d.id = a.diet_plan_id LEFT JOIN workout_templates w ON w.id = a.workout_template_id WHERE a.user_id = ? ORDER BY a.created_at DESC');
$assignmentQuery->execute([$userId]);
$assignments = $assignmentQuery->fetchAll();
$suggestionQuery = $pdo->prepare('SELECT * FROM admin_suggestions WHERE user_id = ? ORDER BY created_at DESC');
$suggestionQuery->execute([$userId]);
$suggestions = $suggestionQuery->fetchAll();

$activityDefinitions = [
    'Recent workouts' => 'SELECT title, workout_date, duration_minutes FROM workout_sessions WHERE user_id = ? ORDER BY workout_date DESC LIMIT 10',
    'Recent measurements' => 'SELECT measured_on, weight_kg, body_fat_percent FROM body_measurements WHERE user_id = ? ORDER BY measured_on DESC LIMIT 10',
    'Fitness goals' => 'SELECT title, status, target_value, unit FROM fitness_goals WHERE user_id = ? ORDER BY created_at DESC LIMIT 10',
    'Recent food logs' => 'SELECT food_name, meal_type, calories, logged_at FROM food_logs WHERE user_id = ? ORDER BY logged_at DESC LIMIT 10',
    'Recent water logs' => 'SELECT logged_on, amount_ml FROM water_logs WHERE user_id = ? ORDER BY logged_on DESC LIMIT 10',
];
$activity = [];
foreach ($activityDefinitions as $label => $sql) {
    $query = $pdo->prepare($sql);
    $query->execute([$userId]);
    $activity[$label] = $query->fetchAll();
}

$pageTitle = 'User details';
require __DIR__ . '/../includes/header.php';
?>
<section class="page-heading"><div><p class="eyebrow">MEMBER PROFILE</p><h1><?= e($user['name']) ?></h1><p><?= e($user['email']) ?></p></div></section>
<?php if ($error): ?><div class="alert error"><?= e($error) ?></div><?php endif; ?>
<section class="panel"><h2>Personal and membership details</h2><div class="detail-grid">
<?php foreach (['age'=>'Age','gender'=>'Gender','fitness_level'=>'Fitness level','fitness_goal'=>'Fitness goal','dietary_preference'=>'Diet preference','food_allergies'=>'Allergies / restrictions','available_days'=>'Available days','height_cm'=>'Height (cm)','weight_kg'=>'Weight (kg)','subscription_status'=>'Subscription','subscription_plan'=>'Plan','subscription_expires_at'=>'Expiry date','created_at'=>'Registered'] as $key => $label): ?>
<div><small><?= e($label) ?></small><strong><?= e((string) ($user[$key] ?? '—')) ?></strong></div>
<?php endforeach; ?>
</div></section>
<section class="panel"><h2>Fitness activity history</h2>
<?php foreach ($activity as $label => $rows): ?><h3><?= e($label) ?></h3>
<?php if (!$rows): ?><p class="muted">No records.</p><?php else: ?><div class="table-wrap"><table><tbody><?php foreach ($rows as $row): ?><tr><?php foreach ($row as $value): ?><td><?= e((string) ($value ?? '—')) ?></td><?php endforeach; ?></tr><?php endforeach; ?></tbody></table></div><?php endif; ?>
<?php endforeach; ?></section>
<section class="panel"><h2>Assign a diet or workout plan</h2><form method="post" class="form-grid">
<input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>"><input type="hidden" name="action" value="assign">
<div><label>Diet plan</label><select name="diet_plan_id"><option value="0">No diet plan</option><?php foreach ($dietOptions as $option): ?><option value="<?= (int) $option['id'] ?>"><?= e($option['title'] . ' · ' . $option['access_type']) ?></option><?php endforeach; ?></select></div>
<div><label>Workout plan</label><select name="workout_template_id"><option value="0">No workout plan</option><?php foreach ($workoutOptions as $option): ?><option value="<?= (int) $option['id'] ?>"><?= e($option['title'] . ' · ' . $option['access_type']) ?></option><?php endforeach; ?></select></div>
<div class="full"><label>Assignment note</label><textarea name="assignment_note" rows="2"></textarea></div><div><button class="button">Assign plan</button></div></form>
<?php foreach ($assignments as $assignment): ?><p><?= e($assignment['diet_title'] ?? '') ?> <?= e($assignment['workout_title'] ?? '') ?> <small><?= e($assignment['created_at']) ?></small></p><?php endforeach; ?></section>
<section class="panel"><h2>Send personalized suggestion</h2><form method="post" class="form-grid"><input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>"><input type="hidden" name="action" value="suggest">
<div><label>Fitness level</label><select name="fitness_level"><option value="beginner" <?= $user['fitness_level'] === 'beginner' ? 'selected' : '' ?>>Beginner</option><option value="intermediate" <?= $user['fitness_level'] === 'intermediate' ? 'selected' : '' ?>>Intermediate</option><option value="expert" <?= in_array($user['fitness_level'], ['expert','advanced'], true) ? 'selected' : '' ?>>Expert</option></select></div>
<div><label>Suggestion title</label><input name="title" required></div><div class="full"><label>Suggestion</label><textarea name="suggestion" rows="4" required></textarea></div><div><button class="button">Save and notify user</button></div></form></section>
<section class="panel"><h2>Previous suggestions</h2><?php foreach ($suggestions as $suggestion): ?><article class="notification-row"><div><strong><?= e($suggestion['title']) ?></strong><p><?= nl2br(e($suggestion['suggestion'])) ?></p><small><?= e($suggestion['created_at']) ?></small></div></article><?php endforeach; ?></section>
<?php require __DIR__ . '/../includes/footer.php'; ?>
