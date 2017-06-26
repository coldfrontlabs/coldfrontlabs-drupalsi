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
                       $drush_alias = undef,
                       $site_aliases = undef,
                       $auto_drush_alias = false,
                       $auto_alias = true,
                       $local_settings = undef,
                       $additional_settings = undef # deprecated
) {
  include drush
  include stdlib

  # Build the site root based on the distro information
  $distros = hiera("drupalsi::distros")
  $distro_root = $distros[$distro]['distro_root']
  $site_root = "$distro_root/$distro"

  if !$sites_subdir or empty($sites_subdir) {
    $sitessubdir = $name
  }
  else {
    $sitessubdir = $sites_subdir
  }

  # @todo create checks for other db types.
  $db_exists_check = "test ! \$(drush sqlq --db-url=${db_url} 'SELECT COUNT(DISTINCT table_name) FROM information_schema.columns WHERE table_schema = (SELECT DATABASE());' --extra='-r -s') -gt 0"

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
    onlyif => ["test ! -f ${site_root}/sites/${sitessubdir}/settings.php -a -f ${site_root}/index.php", "${db_exists_check}"],
    require => [
      Drupalsi::Distro[$distro],
    ]
  }

  # Set drush alias values
  if $auto_drush_alias {
  #  # Set the alias name
  #  if $drush_alias {
  #    $a = $drush_alias
  #  }
  #  else {
  #    $a = $name
  #  }

  #  # Set the group name
  #  if $distros[$distro]['group_alias'] {
  #    $g = $distros[$distro]['group_alias']
  #  }
  #  else {
  #    $g = $distro
  #  }

  #  drush::drush_alias_file {"drush-site-alias-${a}":
  #    name => $a,
  #    group => $g,
  #    root => $site_root,
  #    os => 'Linux', # @todo determine this with Facter
  #    # @todo everything else!
  #  }
  }

  # Build the public files directories
  if !$public_dir or empty($public_dir) {
    $pubdir = "sites/${sitessubdir}/files"
  }
  else {
    # Check if absolute or relative.
    # We need this to start updating to newer puppet stdlib.
    if is_absolute_path($public_dir) {
      # Only create the directory.
      # Absolute path assumes symlink to external
      # file location managed by the admin.
      # Don't set a value in settings.local or
      # provision the dir within the
      # Drupal root.
      file {"drupalsi-public-files-${name}":
        path => "${public_dir}",
        ensure => 'directory',
        mode => '0664',
        owner => $webserver_user,
        recurse => false,
        require => Drush::Si["drush-si-${name}"],
        checksum => 'none',
      }
    }
    else {
      $pubdir = "${public_dir}"
    }
  }

  if $pubdir {
    file {"drupalsi-public-files-${name}":
      path => "${site_root}/${pubdir}",
      ensure => 'directory',
      mode => '0664',
      owner => $webserver_user,
      recurse => false,
      require => Drush::Si["drush-si-${name}"],
      checksum => 'none',
    }

    # Set the permissions in the files dir.
    exec { "enforce drupalsi-public-files-${name} permissions":
      command => "/bin/chown ${webserver_user}:${webserver_user} ${pubdir}",
      require => File["drupalsi-public-files-${name}"],
    }

    # Ensure there's an .htaccess file present.
    file {"drupalsi-public-files-${name}-htaccess":
      path => "${pubdir}/.htaccess",
      ensure => 'present',
      mode => '0444',
      owner => $webserver_user,  #@todo determine the webserver user's name
      require => File["drupalsi-public-files-${name}"],
    }

    file_line {"drupalsi-${name}-default-settings-public-dir}":
     path => "${site_root}/sites/${sitessubdir}/settings.local.php",
      line => "\$conf['file_public_path'] = '${pubdir}';",
      require => [File["drupalsi-public-files-${name}"], File["drupalsi-${name}-local-settings"]],
    }
  }

  # Build the private file directories
  if !$private_dir or empty($private_dir) {
    $privdir = "${pubdir}/private"
  }
  else {
    # Check if absolute or relative.
    # We need this to start updating to newer puppet stdlib.
    if is_absolute_path($private_dir) {
      $privdir = $private_dir
    }
    else {
      $privdir = "${pubdir}/${private_dir}"
    }
  }

  if $privdir {
    # Fail on relative paths.
    validate_absolute_path($privdir)

    file {"drupalsi-private-dir-${name}":
      path => "${privdir}",
      ensure => 'directory',
      mode => '0664',
      owner => $webserver_user,  #@todo determine the webserver user's name
      recurse => false,
      require => Drush::Si["drush-si-${name}"],
      checksum => 'none',
    }

    exec { "enforce drupalsi-private-dir-${privdir} permissions":
      command => "/bin/chown ${webserver_user}:${webserver_user} ${privdir}",
      require => File["drupalsi-private-dir-${name}"],
    }

    # Make sure the file permissions on the htaccess file are different from the rest
    file {"drupalsi-private-dir-${privdir}-htaccess":
      path => "${privdir}/.htaccess",
      ensure => 'present',
      mode => '0444',
      content => template('drupalsi/htaccess-private.erb'),
      owner => $webserver_user,  #@todo determine the webserver user's name
      require => File["drupalsi-private-dir-${name}"],
    }

    file_line {"drupalsi-${name}-default-settings-private-dir}":
      path => "${site_root}/sites/${sitessubdir}/settings.local.php",
      line => "\$conf['file_private_path'] = '${privdir}';",
      require => [File["drupalsi-private-dir-${name}"], File["drupalsi-${name}-local-settings"]],
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
   $command = "drush --quiet --yes --root=${site_root} cron"
   $run_command = "/usr/bin/env PATH=$path COLUMNS=72"

    cron {"drupalsi-site-cron-${name}":
      ensure   => 'present',
      command  => "${run_command} ${command}",
      user     => $webserver_user,
      minute   => $min,
      hour     => $hour,
      monthday => $monthday,
      month    => $month,
      weekday  => $weekday,
      require  => Drush::Si["drush-si-${name}"],
    }
  }

  # Add local settings to settings.php
  if $additional_settings {
    # Do nothing, remove the file
    warning('additional_settings is deprecated. User local_settings instead. Your additional_settings will NOT be applied.')
    file {"drupalsi-{$name}-additional-settings":
      path => "${site_root}/sites/${sitessubdir}/additional_settings.php",
      ensure => 'absent',
      mode => '0444',
      require => Drush::Si["drush-si-${name}"],
    }
  }

  $localsettings = "\$conf['file_public_path'] = '${pubdir}';\r\n\$conf['file_private_path'] = '${privdir}';\r\n${local_settings}"

  # Create settings.local.php file
  file {"drupalsi-${name}-local-settings":
    path => "${site_root}/sites/${sitessubdir}/settings.local.php",
    ensure => 'present',
    mode => '0664',
    content => template('drupalsi/settings.local.php.erb'),
    require => Drush::Si["drush-si-${name}"],
  }

  file_line {"drupalsi-${name}-settings-require}":
    path => "${site_root}/sites/${sitessubdir}/settings.php",
    line => "if (file_exists(__DIR__ . '/settings.local.php')) {include_once __DIR__ . '/settings.local.php';}",
    require => File["drupalsi-${name}-local-settings"],
  }

  # Add entries into sites.php
  $site_alias_defaults = {
    'directory' => $sitessubdir,
    'sites_file' => "${site_root}/sites/sites.php",
  }

  # @todo add automatic entry if required
  if $auto_alias and $base_url {
    $url_parts = split($base_url, '://')
    # @todo Add support for ports in base_url (ex: http://mydomain.com:8080)
    # @todo Add support for paths in base_url (ex: http://mydomain.com:8080/subdir)
    if is_domain_name($url_parts[1]) {
      $generated_alias = {
        "${base_url}" => {
          domain => $url_parts[1],
        },
      }
      create_resources(drupalsi::site::site_alias, $generated_alias, $site_alias_defaults)

    }
  }

  # Add manually defined resources
  if $site_aliases and is_hash($site_aliases) {
    create_resources(drupalsi::site::site_alias, $site_aliases, $site_alias_defaults)
  }
}

define drupalsi::site::site_alias($domain,
                                  $port = undef,
                                  $path = undef,
                                  $directory,
                                  $sites_file
) {

  # Build the site alias entry
  if $port {
    $p = "${port}."
  }

  if $path {
    $pth = ".${path}"
  }

  $parsed_alias = "\$sites['${p}${domain}${pth}'] = '${directory}';"
  file_line{"${name}":
    path => $sites_file,
    line => $parsed_alias,
    require => File[$sites_file],
    ensure => 'present',
  }
}
