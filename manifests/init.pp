# @todo get the arguments from drush si and the install.sh file as setup to be
# passed in via hiera
class drupalsi () {
  $distros = hiera('drupalsi')
  create_resources('drupalsi::distro', $distros)
}