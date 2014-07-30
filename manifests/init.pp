# @todo Add documentation block here
# @todo Add Drupal site installation verification (ex: onlyif to check the install profile used).
class drupalsi () {
  include drush

  $distros = hiera_hash('drupalsi::distros', {})
  create_resources(drupalsi::distro, $distros)

  $profiles = hiera_hash('drupalsi::profiles', {})
  create_resources(drupalsi::profile, $profiles)

  $sites = hiera_hash('drupalsi::sites', {})
  create_resources(drupalsi::site, $sites)
}
