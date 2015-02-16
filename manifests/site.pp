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
                       $additional_settings = undef
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

  # Build the files directories
  if !$public_dir {
    $pubdir = "${sitessubdir}/files"
  }

  file {"drupalsi-public-files-${name}":
    path => "${site_root}/sites/${pubdir}",
    ensure => 'directory',
    mode => '0644',
    owner => $webserver_user,
    group => $webserver_user,
    recurse => true,
    require => Drush::Si["drush-si-${name}"],
  }->
  file {"drupalsi-public-files-${name}-htaccess":
    path => "${site_root}/sites/${pubdir}/.htaccess",
    ensure => 'present',
    mode => '0444',
    owner => $webserver_user,  #@todo determine the webserver user's name
    group => $webserver_user,  #@todo determine the webserver user's name
    require => Drush::Si["drush-si-${name}"],
  }

  if $private_dir {
    file {"drupalsi-private-dir-${private_dir}":
      path => "${private_dir}",
      ensure => 'directory',
      mode => '0644',
      owner => $webserver_user,  #@todo determine the webserver user's name
      recurse => true,
      require => Drush::Si["drush-si-${name}"],
    }->
    # Make sure the file permissions on the htaccess file are different from the rest
    file {"drupalsi-private-dir-${private_dir}-htaccess":
      path => "${private_dir}/.htaccess",
      ensure => 'present',
      mode => '0444',
      owner => $webserver_user,  #@todo determine the webserver user's name
      group => $webserver_user,  #@todo determine the webserver user's name
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
   $command = "drush --quiet --yes --root=${site_root} -l ${sitessubdir} cron"
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

  # Add additional settings to settings.php
  # @todo see if we can create an augeas lense to do this better
  if $additional_settings {
    file {"drupalsi-{$name}-additional-settings":
      path => "${site_root}/sites/${sitessubdir}/additional_settings.php",
      ensure => 'present',
      mode => '0444',
      content => template('drupalsi/additional_settings.php.erb'),
      require => Drush::Si["drush-si-${name}"],
    }->
    file_line {"drupalsi-{$name}-settings-require}":
      path => "${site_root}/sites/${sitessubdir}/settings.php",
      line => "require_once('additional_settings.php');",
      require => Drush::Si["drush-si-${name}"],
    }
  }

  # Add entries into sites.php
  # @todo add automatic entry if required
  if $auto_alias {
    # @todo parse parts of the URL (get path, port and domain)
    # @todo build the alias entry
  }

  # Add manually defined resources
  if $site_aliases {
    $site_alias_defaults = {
      'directory' => $sitessubdir,
      'sites_file' => "${site_root}/sites/sites.php",
    }

    create_resources(drupalsi::site::site_alias, $site_aliases, $site_alias_defaults)
  }
}

define drupalsi::site::site_alias($domain = $name,
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

  $parsed_alias = inline_template("\$sites['<%= $p+$domain+$path %>'] = '<%= $directory %>'")

  file_line{"${name}":
    path => $sites_file,
    line => $parsed_alias,
    require => File[$sites_file],
    ensure => 'present',
  }
}
