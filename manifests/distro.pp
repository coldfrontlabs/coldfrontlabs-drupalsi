# Defines a drupalsi::distro resource

define drupalsi::distro ($distribution) {
  include drush

  # Download the distro and place it in the proper location
  # Ex: drush dl drupal-7.28 --destination=/var/www/html/drupal -y

  $profiles = hiera_hash("drupalsi::${distribution}::profiles")
  create_resources('drupalsi::profile', $profiles, $distribution)

  $sites = hiera_hash("drupalsi::${distribution}::sites")
  create_resources('drupalsi::site', $sites, $distribution)
}
