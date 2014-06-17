# Defines a drupalsi::site resource

define drupalsi::site ($profile,
                       $db_url,
                       $distro,
                       $webserver_user,
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
                       $public_dir = undef,
                       $private_dir = undef,
                       $tmp_dir = undef,
                       $cron_schedule = undef,
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

  # Build the files directories
  if !$public_dir {
    $pubdir = "${sitessubdir}/files"
  }

  file {"drupalsi-public-files-${name}":
    path => "${site_root}/sites/${pubdir}",
    ensure => 'directory',
    mode => '0755',
    owner => $webserver_user,
    recurse => true,
    require => Drush::Si["drush-si-${name}"],
  }

  if $private_dir {
    file {"drupalsi-private-dir-${private_dif}":
      path => "${private_dir}",
      ensure => 'directory',
      mode => '0755',
      owner => $webserver_user,  #@todo determine the webserver user's name
      recurse => true,
      require => Drush::Si["drush-si-${name}"],
    }
  }


  # Configure cron for the site
  if $cron_schedule {
    if $cron_schedule['minute'] {
      $min = $cron_schedule['minute']
    }
    else {
      $min = '0'
    }
    if $cron_schedule['hour'] {
      $hour = $cron_schedule['hour']
    }
    else {
      $hour = '*/1'
    }
    if $cron_schedule['day'] {
      $day = $cron_schedule['day']
    }
    else {
      $day = '*'
    }
    if $cron_schedule['monthday'] {
      $monthday = $cron_schedule['monthday']
    }
    else {
      $monthday = '*'
    }
    if $cron_schedule['month'] {
      $month = $cron_schedule['month']
    }
    else {
      $month = '*'
    }
    if $cron_schedule['weekday'] {
      $weekday = $cron_schedule['weekday']
    }
    else {
      $weekday = '*'
    }

  	# Build the command strings.
  	$command = "drush --quiet --yes --root=${site_root}/sites/${sitessubdir} cron"
  	$run_command = "/usr/bin/env PATH=$path COLUMNS=72"

    cron {"drupalsi-site-cron-${name}":
    	ensure   => 'present',
    	command  => "${run_command} ${command}",
    	user     => $webserver_user,
    	minute   => $minute,
    	hour     => $hour,
      day      => $day,
      monthday => $monthday,
      month    => $month,
      weekday  => $weekday,
    }
  }
}
