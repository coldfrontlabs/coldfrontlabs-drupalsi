# Generate Drupal sites.
class drupalsi::sites {
  $sites = lookup('drupalsi::sites', {default_value => {}})
  ensure_resources(drupalsi::site, $sites)
}
