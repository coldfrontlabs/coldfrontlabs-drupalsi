# Generate Drupal distro instances.
class drupalsi::distros {
  $distros = lookup('drupalsi::distros', {default_value => {}})
  ensure_resources(drupalsi::distro, $distros)
}
