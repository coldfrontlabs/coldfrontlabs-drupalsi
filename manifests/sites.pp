# Generate Drupal sites.
class drupalsi::sites {
  $sites = lookup('drupalsi::sites', {default_value => {}})
  create_resources(drupalsi::site, $sites)
}
