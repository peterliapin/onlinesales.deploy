#!/bin/bash

# Shell script to generate secure environment variables
# Run this script to create a .env file with secure random passwords

set -e

# Use POSIX random for all password generation to avoid encoding issues
rand_char() {
    local chars="$1"
    local count="${2:-1}"
    local result=""
    for ((i=0; i<count; i++)); do
        idx=$(( RANDOM % ${#chars} ))
        result="${result}${chars:$idx:1}"
    done
    echo -n "$result"
}

generate_secure_password() {
    local length="${1:-32}"
    local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    rand_char "$chars" "$length"
}

generate_jwt_secret() {
    generate_secure_password 64
}

generate_complex_password() {
    local length="${1:-12}"
    if [ "$length" -lt 6 ]; then
        echo "Password length must be at least 6." >&2
        exit 1
    fi

    local upper=ABCDEFGHIJKLMNOPQRSTUVWXYZ
    local lower=abcdefghijklmnopqrstuvwxyz
    local digits=0123456789
    local special='@%!'
    local all="$upper$lower$digits$special"

    # Ensure at least one character from each set
    local password=""
    password+=$(rand_char "$upper" 1)
    password+=$(rand_char "$lower" 1)
    password+=$(rand_char "$digits" 1)
    password+=$(rand_char "$special" 1)

    # Fill the rest
    for ((i=4; i<length; i++)); do
        password+=$(rand_char "$all" 1)
    done

    # Shuffle the password (POSIX way)
    password=$(echo "$password" | fold -w1 | awk 'BEGIN{srand()} {a[NR]=$1} END{for(i=1;i<=NR;i++){j=int(rand()*NR)+1; tmp=a[i]; a[i]=a[j]; a[j]=tmp} for(i=1;i<=NR;i++) printf "%s", a[i]; print ""}')
    echo "$password"
}

if [ ! -f ".env.sample" ]; then
    echo "Error: .env.sample file not found!"
    echo "Please make sure you're running this script from the docker-compose directory."
    exit 1
fi

echo "Generating secure environment variables..."
echo "Reading template from .env.sample..."

env_template=$(cat .env.sample)

jwt_secret=$(generate_jwt_secret)
admin_password=$(generate_complex_password 12)
admin_password=$(echo "$admin_password" | xargs) # trim whitespace
if [ "${#admin_password}" -ne 12 ]; then
    echo "Error: Generated admin password is not 12 characters!" >&2
    exit 1
fi
echo "DEBUG: Admin password length: ${#admin_password}"
postgres_password=$(generate_secure_password 16)
elastic_password=$(generate_secure_password 16)

echo
echo "Generated secure values:"
echo "JWT__SECRET=$jwt_secret"
echo "DEFAULTUSERS__0__PASSWORD=$admin_password"
echo "POSTGRES__PASSWORD=$postgres_password"
echo "ELASTIC__PASSWORD=$elastic_password"

env_content="$env_template"
env_content="${env_content//your-super-secret-jwt-key-at-least-32-characters-long/$jwt_secret}"
env_content="${env_content//your-application-issuer/leadcms-issuer}"
env_content="${env_content//your-application-audience/leadcms-audience}"
env_content="${env_content//YourSecurePassword123!/$admin_password}"
env_content="${env_content//YourSecurePostgresPassword123!/$postgres_password}"
env_content="${env_content//YourSecureElasticPassword123!/$elastic_password}"

if [ -f ".env" ]; then
    echo
    echo "Warning: .env file already exists!"
    read -p "Do you want to overwrite it? (y/N) " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled. Your existing .env file was not modified."
        exit 0
    fi
fi

echo -n "$env_content" > .env
echo
echo "Created .env file with secure passwords!"
echo "Please review and customize the .env file before starting the application."
echo
echo "Next steps:"
echo "1. Review the generated .env file"
echo "2. Update EMAIL__USERNAME and EMAIL__PASSWORD with your SMTP credentials"
echo "3. Update CORS__ALLOWEDORIGINS if needed"
echo "4. Add any optional API keys (commented in .env.sample)"
echo "5. Run: docker-compose up -d"
