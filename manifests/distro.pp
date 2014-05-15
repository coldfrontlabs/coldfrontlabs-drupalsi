# Defines a drupalsi::distro resource

define drupalsi::distro ($distro) {
  include drush

  # Download the distro and place it in the proper location
  # Ex: drush dl drupal-7.28 --destination=/var/www/html/drupal -y

  if ($distro::distro_build_type == 'get') {
    drush::dl {"drush-dl-${distro::distribution}-${distro::distro_version}":
      source => $distro::distro_build_location,
      destination => "${distro::distro_root}/${distro::distribution}",
      require => File[$distro::distro_root]
    }
  }

  create_resources('drupalsi::profile', ${distro::profiles})
  create_resources('drupalsi::site', ${distro::sites})


  # Generate the sites.php file for all sites installed on this distro
}
