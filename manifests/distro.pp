# Defines a drupalsi::distro resource

define drupalsi::distro ($distribution = 'drupal', $core = '7.x', $version = 'latest', $build_location = 'https://updates.drupal.org/release-history', $build_type = 'get', $site_root = '/var/www/html/drupal', $build_args = '') {
  include drush

  $profiles = hiera_hash("drupalsi::${distribution}::profiles")
  create_resource('drupalsi::profile', $profiles)
}
