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
) {
  include drush


  drush::si {"drush-si-${name}-${site_name}-${base_url}":
    source => $distro_build_location,
    destination => $distro_root,
    project_name => $distribution,
    default_major => $api_version,
    drupal_project_rename => $name,
    onlyif => "test ! -f ${distro_root}/${name}/index.php",
  }

  # Ex: drush si --root=${distribution}::site_root --destination=${site}::sites_subdir --db-url=${sites}::db_url ...
  # Also need the distro_root value from the distro the site is being installed and set the --root option for drush
}
