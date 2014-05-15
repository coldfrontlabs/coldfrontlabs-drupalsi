# Defines a drupalsi::distro resource

# Defines a drupalsi::distro resource

define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 7,
                         $distro_root = '/var/www/html',
                         $distro_build_type = 'get',
                         $distro_build_location = 'https://updates.drupal.org/release-history',
                         $distro_build_args = undef,
                         $profiles = undef,
                         $sites = undef
                         ) {

  # Download the distro and place it in the proper location
  # Ex: drush dl drupal-7.28 --destination=/var/www/html/drupal -y

  if ($distro_build_type == 'get') {

    # Set some defaults for the GET build type
    if !$distro_build_location {
      $distro_build_location = ''
    }

    drush::dl {"drush-dl-${name}-${distro[distribution]}-${distro[distro_version]}":
      source => $distro_build_location,
      destination => "${distro_root}/${distribution}",
      project_name => $distribution,
      default_major => $api_version
    }
  }

  #create_resources('drupalsi::profile', ${distro::profiles})
  #create_resources('drupalsi::site', ${distro::sites})


  # Generate the sites.php file for all sites installed on this distro
}
