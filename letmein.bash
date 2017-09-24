#!/bin/bash
# curl -s https://raw.githubusercontent.com/renatofrota/letmein/master/letmein.bash | bash
echo -e "\n\tletmein - v0.0.1 - https://github.com/renatofrota/letmein\n";
initialdir=$(pwd);
hostname=$(hostname);
unset lmikeep;
unset lmipause;
wps=$(find $(pwd) -type f -name wp-blog-header.php 2>/dev/null | wc -l);
[[ "$wps" -ge 2 ]] && read -${BASH_VERSION+e}rp "$wps installations found. Pause (and remove) after each one? 1/0: " lmipause;
[[ "$wps" == 0 ]] && echo "WP core dir not found. Try running from the directory wp-blog-header.php is located." || {
	[[ "$wps" -gt "1" ]] && lmikeep=1 ;
	for dirname in $(find $(pwd) -type f -name wp-blog-header.php 2>/dev/null | xargs -I % dirname %); do
		lmistep=0;
		unset lmi;
		cd $dirname;
		letmein="letmein";
		while true; do
			exists=$(/bin/ls $letmein.php 2>/dev/null | wc -l);
			[[ "$exists" -ge "1" ]] && read -${BASH_VERSION+e}rp "$letmein.php exists. choose another filename, without extension: " letmein || break;
		done;
		lmikey=$(date +%s);
		url=$(wp option list --search=siteurl --field=option_value --skip-plugins --skip-themes 2>/dev/null | tail -1 | sed 's,/$,,');
		[[ "$dirname" =~ staging/[[:digit:]] ]] && staging=$(echo $(pwd) | sed -e 's,.*\(.$\),\1,') && url=$(echo $url | sed -e "s,://\(www.\)\?,://\1staging$staging.,");
		[[ ! -z "$url" ]] && {
			lmistep=1;
			admin=$(wp user list --fields=ID,user_login --role=administrator --skip-plugins --skip-themes --format=csv | grep -v "^ID" | sort -n | head -1);
			id=$(echo $admin | cut -d , -f 1);
			un=$(echo $admin | cut -d , -f 2-);
			url2=$(echo $url | sed "s@//@//skipdns.link/$hostname/@" );
			echo -e '<?php //LETMEIN\n@unlink(__FILE__);
			\n\n// Validate request\nif($_REQUEST["key"] != "LMIKEY"){\n\tdie("Unauthorized Access");
			\n}\n\nrequire("wp-blog-header.php");
			\nrequire("wp-includes/pluggable.php");
			\n\n$id=(isset($_REQUEST["id"])) ? $_REQUEST["id"] : 1;
			\n\n$user_info = get_userdata($id);
			\n// Automatic login //\n$username = $user_info->user_login;
			\n$user = get_user_by("login", $username );
			\n// Redirect URL //\nif ( !is_wp_error( $user ) )\n{\n\twp_clear_auth_cookie();
			\n\twp_set_current_user ( $user->ID );
			\n\twp_set_auth_cookie  ( $user->ID );
			\n\n\t$redirect_to = user_admin_url();
			\n\twp_safe_redirect( $redirect_to );
			\n\n\texit();
			\n}' | sed "s,LMIKEY,$lmikey," > $letmein.php;
			echo -e "\nMagic links to login on WP installed at $dirname as $un\n\nRegular: $url/$letmein.php?key=$lmikey&id=$id\nSkipDNS: $url2/$letmein.php?key=$lmikey&id=$id\n";
			cd $initialdir;
			[[ "$lmipause" == "1" ]] && read -${BASH_VERSION+e}rsp "Press any key to continue..." -n 1 pause && rm -fv $dirname/$letmein.php || {
				[[ "$wps" -le "1" ]] && sleep 15 && echo -n "Time is over. " && rm -fv $dirname/$letmein.php;
			}
		} || {
			[[ "$lmistep" != "1" ]] && echo "'wp option list --search=siteurl --field=option_value --skip-plugins --skip-themes' failed. is all fine with this WP install? ($(pwd))";
		};
	done;
};
cd $initialdir;
function killme {
    rm -- "$0";
}
trap killme EXIT
