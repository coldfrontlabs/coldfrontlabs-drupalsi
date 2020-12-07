# Defines a drupalsi::distro resource
define drupalsi::distro (
  $distribution = 'drupal',
  $api_version = 7,
  $distro_root = '/var/www/html',
  $distro_docroot = 'web',
  $distro_build_type = 'get',
  $distro_build_location = 'https://updates.drupal.org/release-history',
  $distro_build_args = {},
  $omit_files = {}
)
{
  include drush

  # Steps:
  # 1. Check if the distro is already there
  # 2. Download the distro and place it in the proper location

  $buildname = md5("${distribution}-${api_version}-${distro_build_type}-${distro_root}-${distro_build_location}-${name}")

  # Drupal 8 always uses Composer.
  if ($distro_build_type == 'composer' or $api_version >= 8) {
    # Do nothing for now.
    # @todo run composer install or just leave it be?

    exec {"create-${buildname}-sites.php":
      creates => "${distro_root}/${name}/${distro_docroot}/sites.php",
      command => "/bin/cp ${distro_root}/${name}/${distro_docroot}/example.sites.php cp ${distro_root}/${name}/${distro_docroot}/sites.php"
    }

    concat {"${distro_root}/${name}/${distro_docroot}/sites.php-settings":
      ensure         => 'present',
      path           => "${distro_root}/${name}/${distro_docroot}/sites/sites.php",
      mode           => '0640',
      ensure_newline => true,
      replace        => false,
      backup         => false,
      show_diff      => true,
      group          => 'apache', # @todo use def modififier collector to fix this to webserver user.
      require => Exec["create-${buildname}-sites.php"],
    }
  }

}
