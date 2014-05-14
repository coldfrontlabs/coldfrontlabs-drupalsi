# Defines a drupalsi::site resource

define drupalsi::site ($site) {
  include drush

  # Ex: drush si --root=${distribution}::site_root --destination=${site}::sites_subdir --db-url=${sites}::db_url ...


  # Available options
  # ------------------
  # profile: 'standard'
  # account_name: 'admin'
  # account_pass: 'adminpassword'
  # account_mail: 'admin@example.com'
  # clean_url: true
  # db_prefix: ''
  # db_su: '<root>'
  # db_su_pw: '<pass>'
  # db_url= 'mysql://root:pass@127.0.0.1/db'
  # locale: '<en_GB>'
  # site_mail: 'admin@example.com'
  # site_name: 'Site Install'
  # sites_subdir: '<directory_name>'
  # base_url: '<https://example.com>'

  # Also need the distro_root value from the distro the site is being installed and set the --root option for drush
}
