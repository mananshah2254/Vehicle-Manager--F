# Database Management - Reset Users

If you can't login and registration says "email already exists", you can reset the database or delete specific users.

## Option 1: Delete Specific User (Recommended)

### On EC2, connect to database:

```bash
# Connect to PostgreSQL container
sudo docker-compose exec postgres psql -U postgres -d vehicle_manager
```

### Check existing users:

```sql
SELECT id, email, created_at FROM users;
```

### Delete specific user:

```sql
-- Replace 'user@example.com' with the email you want to delete
DELETE FROM users WHERE email = 'user@example.com';

-- This will also delete all vehicles for that user (due to CASCADE)
```

### Exit database:

```sql
\q
```

### Try registering again:

Now you can register with that email again.

## Option 2: Reset All Users (Nuclear Option)

**WARNING: This deletes ALL users and vehicles!**

### On EC2:

```bash
# Stop containers
cd ~/vehicle_manager
sudo docker-compose down

# Remove database volume (DELETES ALL DATA!)
sudo docker volume rm vehicle_manager_postgres_data

# Start containers again (fresh database)
sudo docker-compose up -d
```

## Option 3: Check What's in Database

### Connect to database:

```bash
sudo docker-compose exec postgres psql -U postgres -d vehicle_manager
```

### View all users:

```sql
SELECT id, email, created_at FROM users;
```

### View all vehicles:

```sql
SELECT id, user_email, make, model FROM vehicles;
```

### Check user's password hash (for debugging):

```sql
SELECT email, LEFT(password, 20) as password_hash FROM users;
```

Note: Passwords are hashed with bcrypt, so you'll see something like `$2a$10$...` which is normal.

### Exit:

```sql
\q
```

## Option 4: Create Admin Script (Optional)

Create a script to manage users:

```bash
# On EC2
nano ~/reset_user.sh
```

Paste:

```bash
#!/bin/bash
EMAIL=$1

if [ -z "$EMAIL" ]; then
  echo "Usage: ./reset_user.sh user@example.com"
  exit 1
fi

sudo docker-compose exec -T postgres psql -U postgres -d vehicle_manager << EOF
DELETE FROM users WHERE email = '$EMAIL';
SELECT 'User $EMAIL deleted' as result;
EOF
```

Make executable:

```bash
chmod +x ~/reset_user.sh
```

Use it:

```bash
~/reset_user.sh user@example.com
```

## Common Issues

### Issue: "Email already exists" but can't login

**Cause**: User exists in database but password is wrong or corrupted.

**Solution**: Delete user (Option 1) and re-register.

### Issue: Password doesn't work after migration

**Cause**: If you had data from old SharedPreferences system, passwords weren't hashed. New system requires bcrypt hashed passwords.

**Solution**: Delete all users and re-register with new system.

### Issue: Database connection error

**Solution**:
```bash
# Check container is running
sudo docker-compose ps

# Check logs
sudo docker-compose logs postgres
```

## Verify Password Hashing

Passwords in the database should start with `$2a$` or `$2b$` (bcrypt hash).

If you see plain text passwords, there's a problem with the signup process.

To verify:

```bash
sudo docker-compose exec postgres psql -U postgres -d vehicle_manager -c "SELECT email, LEFT(password, 10) as hash_start FROM users;"
```

Good hash: `$2a$10$...` or `$2b$10$...`
Bad hash: Plain text password

