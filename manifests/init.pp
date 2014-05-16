# @todo get the arguments from drush si and the install.sh file as setup to be
# passed in via hiera
class drupalsi () {
  $distros = hiera_hash('drupalsi', {})
  create_resources('drupalsi::distro', $distros)


  #create_resources('drupalsi::profile', ${distro::profiles})
  create_resources(drupalsi::site, $sites, $distro_settings)

}
