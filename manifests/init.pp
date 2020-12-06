# @todo Add documentation block here
# @todo Add Drupal site installation verification (ex: onlyif to check the install profile used).
class drupalsi () {
  include drush

  # Assume jq is available. If other modules want to fix deps go for it.
  ensure_packages('jq', {'ensure' => 'present'})

  # Add the script to set the Drupal directory permissions.
  file {'drupal-fix-permissions-script':
    ensure  => 'file',
    path    => '/usr/local/bin/drupal-fix-permissions.sh',
    content => template('drupalsi/drupal-fix-permissions.sh.erb'),
    mode    => '0755',
  }

  $distros = lookup('drupalsi::distros', {default_value => {}})
  create_resources(drupalsi::distro, $distros)

  $sites = lookup('drupalsi::sites', {default_value => {}})
  create_resources(drupalsi::site, $sites)
}
