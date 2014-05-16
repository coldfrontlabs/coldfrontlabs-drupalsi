# Defines a drupalsi::site resource

define drupalsi::site ($profile,
                       $db_url,
                       $site_root,
                       $account_name = undef,
                       $account_pass = undef,
                       $account_mail = undef,
                       $clean_url = undef,
                       $db_prefix = undef,
                       $db_su = undef,
                       $db_su_pw = undef,
                       $locale = undef,
                       $site_mail = undef,
                       $site_name = undef,
                       $sites_subdir = undef,
                       $base_url = undef,
                       $keyvalue = undef,
) {
  include drush


  drush::si {"drush-si-${name}-${site_name}-${site_root}":
    profile => $profile,
    db_url => $db_url,
    site_root => $site_root,
    account_name => $account_name,
    account_pass => $account_pass,
    account_mail => $account_mail,
    clean_url => $clean_url,
    db_prefix => $db_prefix,
    db_su => $db_su,
    db_su_pw => $db_su_pw,
    locale => $locale,
    site_mail => $site_mail,
    site_name => $site_name,
    sites_subdir => $sites_subdir,
    settings => $keyvalue,
    onlyif => "test ! -f ${site_root}/sites/${name}/settings.php",
  }

  # Ex: drush si --root=${distribution}::site_root --destination=${site}::sites_subdir --db-url=${sites}::db_url ...
  # Also need the distro_root value from the distro the site is being installed and set the --root option for drush
}
