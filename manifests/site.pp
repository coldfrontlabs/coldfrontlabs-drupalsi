# Defines a drupalsi::site resource

define drupalsi::site ($site) {
  include drush

  # Ex: drush si --root=${distribution}::site_root --destination=${site}::sites_subdir --db-url=${sites}::db_url ...
}
