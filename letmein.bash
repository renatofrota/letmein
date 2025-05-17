#!/bin/bash
# run like this:
# curl -sO https://raw.githubusercontent.com/renatofrota/letmein/master/letmein.bash && bash letmein.bash

rm -f "$0"
echo -e "\n\tLetmein - v1.0.5 - https://github.com/renatofrota/letmein"

if [ -f wp-blog-header.php ]; then
    INSTALLS="./"
else
    INSTALLS=$(find $(pwd) -type f -name wp-blog-header.php)
fi

[[ "$(echo "$INSTALLS" | wc -w)" -gt 1 ]] && echo -e "\n\tMultiple WordPress installs found!\n"

for INSTALL in $INSTALLS; do
    [[ "$(echo "$INSTALLS" | wc -w)" -gt 1 ]] && echo -en "\t" && read -p "Press any key to continue..." -n 1

    INSTALL_DIR=$(realpath $(dirname "$INSTALL"))
    cd "$INSTALL_DIR" || continue
    echo -e "\n\tProcessing WP install at: $INSTALL_DIR"
    rm -f letmein-*.php

    while true; do
        FILE_NAME="letmein-$RANDOM$RANDOM$RANDOM.php"
        if [ ! -f "$FILE_NAME" ]; then
            break
        fi
    done

    cat > "$FILE_NAME" <<EOF
<?php // https://github.com/renatofrota/letmein
if (time() > filemtime(__FILE__) + 86400) {
    @unlink(__FILE__);
    die('Expired');
}
define('WP_USE_THEMES', false);
if (isset(\$_REQUEST['wp_cache_flush']) and \$_REQUEST['wp_cache_flush'] == 1) {
    @unlink(__FILE__);
    require('wp-blog-header.php');
    wp_cache_flush();
    wp_safe_redirect(admin_url());
    exit;
}
define('WP_CONTENT_DIR', __DIR__ . '/letmein-ignore-content');
define('WP_PLUGIN_DIR', __DIR__ . '/letmein-ignore-plugins');
define('WPMU_PLUGIN_DIR', __DIR__ . '/letmein-ignore-mu-plugins');
require('wp-blog-header.php');
require('wp-includes/pluggable.php');
\$_SERVER['SCRIPT_NAME'] = '/wp-login.php';
if (!is_user_logged_in()) {
    \$params = ['role' => 'administrator', 'fields' => 'ID'];
    if (isset(\$_REQUEST['login'])) \$params['login'] = \$_REQUEST['login'];
    \$admins = get_users(\$params);
    if (empty(\$admins)) die('No admin');
    \$user_id = array_rand(array_flip(\$admins));
    wp_clear_auth_cookie();
    wp_set_current_user(\$user_id);
    wp_set_auth_cookie(\$user_id);
    wp_safe_redirect(admin_url());
}
if (class_exists('Redis') or file_exists('wp-content/object-cache.php')) {
    wp_safe_redirect(\$_SERVER['PHP_SELF'].'?wp_cache_flush=1');
    exit;
}
@unlink(__FILE__);
wp_safe_redirect(admin_url());
exit;
EOF

    SITE_URL=$(wp option get siteurl --skip-plugins --skip-themes 2>/dev/null || echo https://example.com)
    echo -e "\tMagic login link generated for $SITE_URL\n"

    LIVE="$SITE_URL/$(basename $FILE_NAME)"
    echo -e "\tRegular => $LIVE"

    JSON_FILE1=~/tmp/skipdns/$(echo "$SITE_URL" | sed 's|https://||' | sed 's|http://||' | sed 's|/||')
    JSON_FILE2=/tmp/skipdns/$(echo "$SITE_URL" | sed 's|https://||' | sed 's|http://||' | sed 's|/||')

    if [ -f "$JSON_FILE1" ] || [ -f "$JSON_FILE2" ]; then
        SKIPDNS_URL=$(grep -oP '"full_url":\s*"\K[^"]+' "$JSON_FILE1" || grep -oP '"full_url":\s*"\K[^"]+' "$JSON_FILE2")
        PREVIEW="$SKIPDNS_URL/$(basename $FILE_NAME)"
        echo -e "\tPreview => $PREVIEW"
    fi

    echo ""
done
