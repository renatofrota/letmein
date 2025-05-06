#!/bin/bash
# run like this:
# bash <(curl -s https://raw.githubusercontent.com/renatofrota/letmein/master/letmein.bash)

echo -e "\n\tLetmein - v1.0.0 - https://github.com/renatofrota/letmein"

# Record creation timestamp to check against expiration
CREATION_TIMESTAMP=$(date +%s)

# Check if wp-blog-header.php exists in current directory, otherwise search in subdirectories
if [ -f wp-blog-header.php ]; then
    INSTALLS="./"
else
    INSTALLS=$(find $(pwd) -type f -name wp-blog-header.php)
fi

# Process each found WP install
for INSTALL in $INSTALLS; do
    INSTALL_DIR=$(realpath $(dirname "$INSTALL"))
    cd "$INSTALL_DIR" || continue
    echo -e "\n\tProcessing WP install at: $INSTALL_DIR"

    # File name selection
    if [ -f "letmein.php" ]; then
        while true; do
            read -p "Enter PHP file name (default: letmein.php): " FILE_NAME
            if [ -z "$FILE_NAME" ]; then
                FILE_NAME="letmein.php"
            fi
            [[ "$FILE_NAME" != *.php ]] && FILE_NAME="$FILE_NAME.php"
            if [ ! -f "$FILE_NAME" ]; then
                break
            fi
            echo "$FILE_NAME already exists. Choose another."
        done
    else
        FILE_NAME="letmein.php"
    fi

    # Generate a new key for each WP install
    LETMEIN_KEY=$RANDOM$RANDOM$RANDOM

    # Generate PHP file
    cat > "$FILE_NAME" <<EOF
<?php
@unlink(__FILE__);
if (time() > $CREATION_TIMESTAMP + 86400) die('Expired');
if (\$_REQUEST['key'] != '$LETMEIN_KEY') die('Unauthoried access');
\$_SERVER['SCRIPT_NAME'] = '/wp-login.php';
define('WPMU_PLUGIN_DIR', __DIR__ . '/$LETMEIN_KEY');
define('WP_PLUGIN_DIR', __DIR__ . '/$LETMEIN_KEY');
define('WP_CONTENT_DIR', __DIR__ . '/$LETMEIN_KEY');
define('WP_USE_THEMES', false);
require('wp-blog-header.php');
wp_cache_flush();
require('wp-includes/pluggable.php');
\$admins = get_users(['role' => 'administrator', 'fields' => 'ID']);
if (empty(\$admins)) die('No admin');
\$user_id = array_rand(array_flip(\$admins));
wp_clear_auth_cookie();
wp_set_current_user(\$user_id);
wp_set_auth_cookie(\$user_id);
wp_safe_redirect(admin_url());
EOF

    # Output magic link
    SITE_URL=$(wp option get siteurl --skip-plugins --skip-themes)
    echo -e "\tMagic login link generated for $SITE_URL\n"

    LIVE="$SITE_URL/$(basename $FILE_NAME)?key=$LETMEIN_KEY"
    echo "Regular => $LIVE"

    # Check for SkipDNS URL and generate preview if exists
    JSON_FILE1=~/tmp/skipdns/$(echo "$SITE_URL" | sed 's|https://||' | sed 's|/||')
    JSON_FILE2=/tmp/skipdns/$(echo "$SITE_URL" | sed 's|https://||' | sed 's|/||')

    if [ -f "$JSON_FILE1" ] || [ -f "$JSON_FILE2" ]; then
        SKIPDNS_URL=$(grep -oP '"full_url":\s*"\K[^"]+' "$JSON_FILE1" || grep -oP '"full_url":\s*"\K[^"]+' "$JSON_FILE2")
        PREVIEW="$SKIPDNS_URL/$(basename $FILE_NAME)?key=$LETMEIN_KEY"
        echo "Preview => $PREVIEW"
    fi

    # Pause between installs if multiple WP installs
    if [ "$(echo "$INSTALLS" | wc -w)" -gt 1 ]; then
        echo -e ""  # Clear line
        read -p "Press any key to continue..." -n 1
    fi
done

echo -e "\n\tUseful? Donate: https://github.com/renatofrota/letmein#donate\n"
