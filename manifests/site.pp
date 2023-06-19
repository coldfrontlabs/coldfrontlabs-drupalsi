# Defines a drupalsi::site resource

define drupalsi::site (
  String $distro,
  String $webserver_user,
  String $siteroot = '',
  String $db_user = '',
  String $db_password = '',
  String $db_name = '',
  String $sites_subdir = '',
  String $public_dir = '',
  String $private_dir = '',
  String $tmp_dir = '',
  Hash $cron_schedule = {},
  Hash $site_aliases = {},
  Hash $env = {},
  Boolean $auto_alias = true,
  Variant[Array[String], String] $local_settings = [],
  Array[String] $domain_names = [],
  # Deprecated arguments
  String $base_url = '',
  Boolean $clean_url = false,
  String $profile = '',
  String $site_mail = '',
  String $account_pass = '',
  String $account_mail = '',
  String $site_name = '',
  String $account_name = '',
  String $db_url = '',
) {
  include ::stdlib

  $distros = lookup('drupalsi::distros')
  $distro_root = $distros[$distro]['distro_root']

  # Build the site root based on the distro information if siteroot is not specified.
  if (empty($siteroot)) {
    $distro_docroot = empty($distros[$distro]['distro_docroot']) ? {
      true => 'web',
      false => $distros[$distro]['distro_docroot']
    }

    $site_root = "${distro_root}/${distro_docroot}"
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
    $run_command = '/usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin COLUMNS=72'

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
  # @todo replace with calls to the setting defined type.
  concat::fragment {"drupalsi-${name}-local-settings":
    target  => "${site_root}/sites/${sitessubdir}/settings.local.php",
    content => template('drupalsi/settings.local.php.erb'),
    order   => 0,
  }

  concat {"${site_root}/sites/${sitessubdir}/settings.php":
    ensure         => 'present',
    path           => "${site_root}/sites/${sitessubdir}/settings.php",
    ensure_newline => true,
    mode           => '0440',
    order          => 'numeric',
    replace        => false,
    backup         => false,
    show_diff      => false,
    group          => $webserver_user # @todo use def modififier collector to fix this to webserver user.
  }

  # Populate the settings.php file with the default values.
  concat::fragment {"drupalsi-${name}-default-settings-php":
    target => "${site_root}/sites/${sitessubdir}/settings.php",
    source => "${site_root}/sites/${sitessubdir}/default.settings.php",
    order  => 0
  }

  # Add reference to settings.local.php
  concat::fragment {"drupalsi-${name}-settings-require}":
    target  => "${site_root}/sites/${sitessubdir}/settings.php",
    content => "if (file_exists(__DIR__ . '/settings.local.php')) {include_once __DIR__ . '/settings.local.php';}",
    order   => 100,
  }

  concat {"${site_root}/sites/${sitessubdir}/settings.local.php":
    ensure         => 'present',
    path           => "${site_root}/sites/${sitessubdir}/settings.local.php",
    ensure_newline => true,
    mode           => '0440',
    order          => 'numeric',
    replace        => true,
    backup         => false,
    show_diff      => false,
    group          => $webserver_user # @todo use def modififier collector to fix this to webserver user.
  }

  # Add entries into sites.php
  $site_alias_defaults = {
    'directory' => $sitessubdir,
    'target' => "${site_root}/sites/sites.php",
  }

  # Add require env varialbes to the distro env file.
  concat::fragment {"${name}-envvars":
    target  => "${distro_root}/.env",
    content => dotenv($env),
    order   => 5
  }

  # Create the sites.php entries.
  $domain_names.each |$domain_name| {
    validate_domain_name($domain_name)

    $trusted_regex = regsubst($domain_name, '(\.)', '\.', 'G')

    $site_alias = {
      "${name}-${domain_name}" => {
        'domain' => $domain_name,
      }
    }

    $trusted_host = {
      "${name}-${domain_name}" => {
        'key' => 'trusted_host_patterns',
        'value' => "^${trusted_regex}\$",
        'append' => true,
        'target' => "${site_root}/sites/${sitessubdir}/settings.local.php"
      }
    }

    ensure_resources(drupalsi::site::site_alias, $site_alias, $site_alias_defaults)
    ensure_resources(drupalsi::site::setting, $trusted_host)
  }
}
