# Generate Drupal distro instances.
class drupalsi::distros {
  $distros = lookup('drupalsi::distros', {default_value => {}})
  create_resources(drupalsi::distro, $distros)
}
