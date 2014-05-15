# Defines a drupalsi::distro resource

define drupalsi::distro ($distro) {
  include drush

  # Download the distro and place it in the proper location
  # Ex: drush dl drupal-7.28 --destination=/var/www/html/drupal -y

  # Set some global defaults for distros
  if !$distro['distribution'] {
    $distro['distribution'] = drupal
  }

  if !$distro['api_version'] {
    $distro['api_version'] = 7
  }

  if !$distro['distro_root'] {
    $distro['distro_root'] = '/var/www/html'
  }


  if ($distro['distro_build_type'] == 'get') {

    # Set some defaults for the GET build type
    if !$distro['distro_build_location'] {
      $distro['distro_build_location'] = ''
    }

    drush::dl {"drush-dl-${name}-${distro[distribution]}-${distro[distro_version]}":
      source => $distro['distro_build_location'],
      destination => "${distro[distro_root]}/${distro[distribution]}",
      project_name => $distro['distribution'],
      default_major => $distro['api_version']
    }
  }

  #create_resources('drupalsi::profile', ${distro::profiles})
  #create_resources('drupalsi::site', ${distro::sites})


  # Generate the sites.php file for all sites installed on this distro
}
