# Defines a drupalsi::site resource

define drupalsi::site (String $distro,
                       String $webserver_user,
                       String $siteroot = '',
                       String $db_user = '';
                       String $db_password = '';
                       String $db_name = '';
                       String $sites_subdir = '',
                       String $base_url = '',
                       String $public_dir = '',
                       String $private_dir = '',
                       String $tmp_dir = '',
                       String $cron_schedule,
                       Hash $site_aliases = {},
                       Boolean $auto_alias = true,
                       Variant[Array[String], String] $local_settings = [],
) {
  include drush
  include stdlib

  $distros = lookup("drupalsi::distros")

  # Build the site root based on the distro information if siteroot is not specified.
  if (empty($siteroot)) {
    $distro_root = $distros[$distro]['distro_root']
    $site_root = "$distro_root/$distro"  
  }
  else {
    $site_root = $siteroot
  }

  if !$sites_subdir or empty($sites_subdir) {
    $sitessubdir = $name
  }
  else {
    $sitessubdir = $sites_subdir
  }

  $confvar_name_d7 = 'conf'
  $confvar_name_d8 = 'settings'

  # Set the var name based on the api version.
  if $distros[$distro]['api_version'] == '8' {
    $confvar_name = $confvar_name_d8  
  }
  else {
    $confvar_name = $confvar_name_d7
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
      exec {"create-drupalsi-public-dir-${name}":
        command => "mkdir -p ${public_dir}",
        creates => $public_dir,
        path => ['/bin', '/usr/bin'],
      }
      
      file {"drupalsi-public-files-${name}":
        path => "${public_dir}",
        ensure => 'directory',
        mode => '0770',
        #owner => $webserver_user,
        recurse => false,
        require => [
          Exec["create-drupalsi-public-dir-${name}"],
        ],
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
      mode => '0770',
      #owner => $webserver_user,
      recurse => false,
      checksum => 'none',
    }

    # Ensure there's an .htaccess file present.
    file {"drupalsi-public-files-${name}-htaccess":
      path => "${site_root}/sites/${sitessubdir}/files/.htaccess",
      ensure => 'present',
      mode => '0440',
      #owner => $webserver_user,  #@todo determine the webserver user's name
      require => File["drupalsi-public-files-${name}"],
      content => template('drupalsi/htaccess-public.erb'),
    }

  }

  # Build the private file directories
  if !$private_dir or empty($private_dir) {
    $privdir = "${site_root}/${pubdir}/private"
  }
  else {
    # Check if absolute or relative.
    # We need this to start updating to newer puppet stdlib.
    if is_absolute_path($private_dir) {
      $privdir = $private_dir
    }
    else {
      $privdir = "${site_root}/${pubdir}/${private_dir}"
    }
  }

  if $privdir {
    # Fail on relative paths.
    validate_absolute_path($privdir)

    exec {"create-drupalsi-private-dir-${name}":
      command => "mkdir -p ${privdir}",
      creates => $privdir,
      path => ['/bin', '/usr/bin'],
    }

    file {"drupalsi-private-dir-${name}":
      path => "${privdir}",
      ensure => 'directory',
      mode => '0770',
      #owner => $webserver_user,  #@todo determine the webserver user's name
      recurse => false,
      require => [
        Exec["create-drupalsi-private-dir-${name}"],
      ],
      checksum => 'none',
    }

    # Make sure the file permissions on the htaccess file are different from the rest
    file {"drupalsi-private-dir-${name}-htaccess":
      path => "${privdir}/.htaccess",
      ensure => 'present',
      mode => '0440',
      content => template('drupalsi/htaccess-private.erb'),
      #owner => $webserver_user,  #@todo determine the webserver user's name
      require => File["drupalsi-private-dir-${name}"],
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
    }
  }

  # Create settings.local.php file
  file {"drupalsi-${name}-local-settings":
    path => "${site_root}/sites/${sitessubdir}/settings.local.php",
    ensure => 'present',
    mode => '0640',
    content => template('drupalsi/settings.local.php.erb'),
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
