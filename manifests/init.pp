# @todo Add documentation block here
# @todo Add Drupal site installation verification (ex: onlyif to check the install profile used).
class drupalsi () {
  include drush

  if $osfamily == 'RedHat' {
    include ::epel
    ensure_packages('jq', {'ensure' => 'present', 'require' => Class['epel']})
  }
  else {
    ensure_packages('jq', {'ensure' => 'present'})
  }

  # Add the script to set the Drupal directory permissions.
  file {'drupal-fix-permissions-script':
    content => template('drupalsi/drupal-fix-permissions.sh.erb'),
    path => '/usr/local/bin/drupal-fix-permissions.sh',
    ensure => 'file',
    mode => '0755',
  }

  $distros = hiera_hash('drupalsi::distros', {})
  create_resources(drupalsi::distro, $distros)

  $profiles = hiera_hash('drupalsi::profiles', {})
  create_resources(drupalsi::profile, $profiles)

  $sites = hiera_hash('drupalsi::sites', {})
  create_resources(drupalsi::site, $sites)
}
