<?php
require_once __DIR__.'/includes/init.php'; require_once __DIR__.'/includes/auth.php';
if(!empty($_SESSION['user_id'])) redirect(($_SESSION['role']??'')==='admin'?'admin/dashboard.php':'dashboard.php');
$error=''; $name=''; $email='';
if($_SERVER['REQUEST_METHOD']==='POST'){
 verifyCsrf(); $name=trim((string)($_POST['name']??'')); $email=strtolower(trim((string)($_POST['email']??'')));
 $password=(string)($_POST['password']??''); $confirm=(string)($_POST['confirm_password']??'');
 $ageRaw=trim((string)($_POST['age']??'')); $age=$ageRaw===''?null:filter_var($ageRaw,FILTER_VALIDATE_INT);
 $gender=$_POST['gender']??''; $level=$_POST['fitness_level']??'beginner'; $goal=$_POST['fitness_goal']??'general_fitness';
 $diet=$_POST['dietary_preference']??'no_preference'; $allergies=trim((string)($_POST['food_allergies']??'')); $days=$_POST['available_days']??[];
 if($name===''||mb_strlen($name)>100) $error='Enter your name (up to 100 characters).';
 elseif(!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($email)>190) $error='Enter a valid email address.';
 elseif(strlen($password)<8) $error='Password must contain at least 8 characters.';
 elseif($password!==$confirm) $error='Passwords do not match.';
 elseif($ageRaw!==''&&($age===false||$age<13||$age>110)) $error='Enter a valid age.';
 elseif(!in_array($gender,['','male','female','other','prefer_not_to_say'],true)) $error='Choose a valid gender option.';
 elseif(!in_array($level,['beginner','intermediate','expert'],true)) $error='Choose a valid fitness level.';
 elseif(!in_array($goal,['general_fitness','strength','endurance','flexibility','mobility'],true)) $error='Choose a valid fitness goal.';
 elseif(!in_array($diet,['no_preference','vegetarian','vegan','pescatarian','other'],true)) $error='Choose a valid dietary preference.';
 else {
  $q=$pdo->prepare('SELECT id FROM users WHERE email=?');$q->execute([$email]);
  if($q->fetch()) $error='An account with this email already exists.';
  else {
   $validDays=array_values(array_intersect(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],is_array($days)?$days:[]));
   $q=$pdo->prepare("INSERT INTO users (name,email,password_hash,role,age,gender,fitness_level,fitness_goal,dietary_preference,food_allergies,available_days,subscription_status,subscription_plan) VALUES (?,?,?,'user',?,?,?,?,?,?,?,'normal',NULL)");
   $q->execute([$name,$email,password_hash($password,PASSWORD_DEFAULT),$age,$gender?:null,$level,$goal,$diet,$allergies?:null,json_encode($validDays)]);
   flash('Your FitTrack account is ready with the Normal (Free) plan. You can upgrade to Premium anytime.'); redirect('login.php');
  }
 }
}
?>
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Create account | FitTrack</title><link rel="stylesheet" href="assets/css/style.css"><link rel="stylesheet" href="assets/css/style2.css"></head><body class="auth-v2"><header class="public-nav"><a class="brand" href="index.php">✦ FitTrack</a><a href="index.php">← Home</a></header><main class="auth-card-v2"><span class="eyebrow">GET STARTED</span><h1>Create your account</h1><p>Tell us a little about your fitness preferences so we can organize relevant guidance.</p><?php if($error):?><div class="alert error"><?=e($error)?></div><?php endif;?>
<form method="post"><input type="hidden" name="csrf_token" value="<?=e(csrfToken())?>"><div class="form-grid"><div class="full"><label>Full name</label><input name="name" maxlength="100" value="<?=e($name)?>" required></div><div class="full"><label>Email</label><input type="email" name="email" value="<?=e($email)?>" required></div><div><label>Password</label><input type="password" name="password" minlength="8" required></div><div><label>Confirm password</label><input type="password" name="confirm_password" minlength="8" required></div><div><label>Age (optional)</label><input type="number" name="age" min="13" max="110"></div><div><label>Gender (optional)</label><select name="gender"><option value="">Prefer not to say</option><option value="male">Male</option><option value="female">Female</option><option value="other">Other</option><option value="prefer_not_to_say">Prefer not to say</option></select></div><div><label>Fitness experience</label><select name="fitness_level"><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="expert">Expert</option></select></div><div><label>Main goal</label><select name="fitness_goal"><option value="general_fitness">General fitness</option><option value="strength">Strength</option><option value="endurance">Endurance</option><option value="flexibility">Flexibility</option><option value="mobility">Mobility</option></select></div><div><label>Diet preference</label><select name="dietary_preference"><option value="no_preference">No preference</option><option value="vegetarian">Vegetarian</option><option value="vegan">Vegan</option><option value="pescatarian">Pescatarian</option><option value="other">Other</option></select></div><div><label>Food allergies / restrictions</label><input name="food_allergies" maxlength="500" placeholder="Optional"></div><div class="full"><label>Days available for exercise</label><div class="day-checks"><?php foreach(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] as $day):?><label><input type="checkbox" name="available_days[]" value="<?=$day?>"> <?=$day?></label><?php endforeach;?></div></div></div><button class="button full" type="submit">Create free account →</button></form><p class="form-foot">Already registered? <a href="login.php">Sign in</a></p></main></body></html>
