# Defines a drupalsi::site resource

define drupalsi::site ($profile,
                       $db_url,
                       $distro,
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

  # Build the site root based on the distro information
  $distros = hiera("drupalsi::distros")
  $distro_root = $distros[$distro]['distro_root']
  $site_root = "$distro_root/$distro"

  if !$sites_subdir {
    $sitessubdir = $name
  }
  else {
    $sitessubdir = $sites_subdir
  }

  drush::si {"drush-si-${name}":
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
    sites_subdir => $sitessubdir,
    settings => $keyvalue,
    onlyif => "test ! -f ${site_root}/sites/${sitessubdir}/settings.php -a -f ${site_root}/index.php",
    require => [
      Drupalsi::Distro[$distro],
      Package['php-cli'],
      Package['php-common'],
      Package['php-gd'],
      Package['php-ldap'],
      Package['php-mbstring'],
      Package['php-mysql'],
      Package['php-pdo'],
      Package['php-process'],
      Package['php-xml'],
      Package['php-xmlrpc'],
      Package['php-devel'],
      Package['php-pear'],
    ]
  }
}
