# FitTrack — PHP + MySQL Starter Project

A beginner-friendly fitness tracker for XAMPP using plain PHP, PDO, MySQL, HTML, CSS, and PHP sessions.

## Included
- Registration, login, logout, CSRF protection, session authentication
- Dashboard with workout and measurement summaries
- Exercise library (view/search; admin management)
- Workout plans and plan exercises
- Workout sessions and sets
- Fitness goals
- Body measurements and progress history
- Basic admin pages
- Responsive CSS
- Optional database schema in `database/schema.sql`

## Setup
1. Copy the `FitTrack` folder into `C:\xampp\htdocs\`.
2. Start Apache and MySQL in the XAMPP Control Panel.
3. Open phpMyAdmin and optionally import `database/schema.sql` to create the tables.
4. Edit `config/database.php` to match your own MySQL credentials.
5. Open `http://localhost/FitTrack/`.
6. Register an account.

## Make an admin account
For safety, registration always creates a normal `user`. After registering, use phpMyAdmin to promote your own account:
```sql
UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
```
Do not expose admin promotion in public registration.

## Notes
- This project is for local learning and should be reviewed before public deployment.
- The default database settings are the common local XAMPP settings only. Configure your own credentials.
- `secure => false` in the session cookie settings is only for local HTTP. Set it to `true` when using HTTPS.
- Add rate limiting, password reset, automated tests, and production deployment hardening before publishing.
- No Apache configuration is included; configure Apache as you prefer.


UPDATED PACKAGE NOTES
- Added body_measurements.php, nutrition.php, and water.php using the uploaded fittrack SQL schema.
- Profile editing now uses the actual users columns (age, gender, height_cm, weight_kg, fitness_level).
- Progress now redirects to Body Measurements.
- The actual imported schema uses workout_sessions.workout_date and body_measurements.measured_on. Back up your existing FitTrack folder before copying these files over it.
- Do not import database/schema.sql over your existing database; it represents an older/different schema. Use your exported fittrack database as the source of truth.


## Subscription feature (added)
- Every new registration automatically receives the **Normal (Free)** plan. No payment is needed to register or use free content.
- Users can later open **Subscription** and request an upgrade to Premium by choosing a duration and uploading payment proof.
- Premium access starts only after an administrator reviews and approves the request. Rejected or pending requests do not grant Premium access.
- Admins can see each user's membership status and expiry date in **Manage users**.


## FitTrack 2.0 upgrade

This package adds a public landing page, separate administrator sign-in (`/admin/login.php`), fitness level and preference registration, Normal (Free) membership by default, optional Premium upgrades by manual payment proof and admin approval, free/premium diet and workout content, SMTP email helper, in-app notifications, coach directory and admin-managed coaching bookings.

### Upgrade safely
1. Back up the current FitTrack folder and export the existing database.
2. Keep the existing database; do not import the older `database/schema.sql` over it.
3. Select the existing FitTrack database in phpMyAdmin and import `database/fittrack_2_migration.sql`. This is an additive migration.
4. Check `config/database.php` and confirm it points to the existing database.
5. Configure `config/payment.php` with verified payment instructions; do not publish unverified bank or wallet details.
6. Run `composer install` in the FitTrack project folder.
7. Configure `config/mail.php` with a Gmail address and Google App Password, then set `enabled` to `true`. Do not use your normal Gmail password or commit the config file with credentials.
8. Ensure PHP has the `fileinfo` extension enabled and that `uploads/payment-proofs` is writable by Apache. The supplied `.htaccess` denies direct web access to uploaded proofs; administrators view proofs through the authenticated `admin/payment-proof.php` controller.
9. Create an admin account by registering a normal user and promoting it in phpMyAdmin: `UPDATE users SET role='admin' WHERE email='your-admin-email@example.com';`. Then sign in at `/admin/login.php`. Public admin registration has been removed.
10. Create diet/workout plans and coaches in the admin panel. Set at least one weekly availability slot when adding each coach; users can only request sessions during configured slots. The user plans page will only show plans that exist in the database and match the user's level/access.

### Important configuration and testing notes
- SMTP is disabled by default until configured. Email failures are logged; in-app notifications remain available.
- New accounts are explicitly saved with `subscription_status='normal'` and no Premium subscription. Users may request Premium later; an uploaded JPG, PNG or PDF payment proof is required, and only admin approval activates the requested period.
- The application stores plan guidance as administrator-authored content; it does not generate medical or diet advice automatically. Review all plan content before publishing.
- The current schema has historical differences documented above. Run this migration only against the actual existing database and test on a backup first.
