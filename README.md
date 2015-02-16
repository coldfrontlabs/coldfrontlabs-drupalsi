Drupal Site Install
===================

This module manages the installation of a Drupal site. It only cares for the installation task.
Managing updates and code changes are the responsibility of the Drupal site itself.
This module only installs a Drupal site if it does not currently exist.

Dependencies
------------

- [Coldfront Drush module](https://github.com/coldfrontlabs/coldfrontlabs-drush)

How it works
------------

Describe the site(s) you want on the server. The information you provide includes the
credentials to the database, the site folder names and the configuration for the
$DRUPAL_ROOT/sites/sites.php if necessary.

You can also specify additional installation profiles to download and add to the available
list of sites (e.g. dropfort_profile)

Lastly, you can specify a whole distribution of Drupal to replace vanialla core.

Sample Hiera configuration
--------------------------

````yaml
drupalsi::distros:
  drupal:                               # Name of the distribution installation
    distribution: drupal-7.28           # Specify a distribution (e.g. commerce_kickstart, wetkit). Defaults to 'drupal'. Include the version optionally.
    api_version: 7                      # Specify which core API version (e.g. 6, 7, 8). Defaults to '7'
    distro_root: '/var/www/html'        # Full path to your Drupal root directory with no trailing slash. This will create your site root folder at '/var/www/html/<distroname>'
    group_alias: default                    # Value to use to create the drush site alias group for sites on this distro. Defaults to the value of 'distribution'.
  dropfort:
    distribution: dropfort                  # Specify a distribution (e.g. commerce_kickstart, wetkit). Defaults to 'drupal'
    api_version: 7                          # Specify which core API version (e.g. 6, 7, 8). Defaults to '7'
    distro_build_location: 'dropfort.make'  # Project download URL for your distribution. Defaults to https://update.drupal.org/release_history
                                            # Full path to the make file to build the site with.

    distro_build_type: 'make'               #  Options:
                                            #    'make'  _>  Build the profile using a drush make file. Optionally from a remote file source. See distro_build_args for more details
                                            #    'git'   _>  Clone the site with Git
                                            #    'get'   _>  Download the Drupal distribution with an HTTP GET request

    distro_root: '/var/www/html'            # Full path to your distro root directory. In this case would create '/var/www/html/dropfort'.
    distro_build_args:                      # Arguments to add to the build_location method. For example with 'get' requests, adds key/value pairs to the URL via querystring parameters. Defaults to ''.

      # Args for the 'make' build type
      url: 'https://git.dropfort.com/dropfort/dropfort_make/raw/7.x-1.x/dropfort.make' # Publicly available URL to a make file
      url_args: 'private_token=1234567'    # URL Encoded string of arguments to append to the URL. Omit the '?' character as it is automatically added.
      # Any arguments from drush make with '-' replaced with '_'
      no_cache: true

      # Args for the 'git' build type
      # @todo


      # Args for the 'drush' build type
      # @todo

drupalsi::sites:
  default:
    profile: 'standard'             # Installation profile to use. Defaults to "standard"
    account_name: 'admin'
    account_pass: 'adminpassword'
    account_mail: 'admin@example.com'
    clean_url: true
    db_prefix: ''
    db_su: '<root>'
    db_su_pw: '<pass>'
    db_url: 'mysql://root:pass@127.0.0.1/db'
    locale: '<en_GB>'
    site_mail: 'admin@example.com'
    site_name: 'Site Install'
    sites_subdir: 'default'
    base_url: '<https://example.com>'
    distro: drupal
    public_dir: "/absolute/path/to/public/files" # Leave blank to default to sites/{name}/files
    private_dir: "/absolute/path/to/private/files" # Leave blank to omit a private files dir
    webserver_user = "apache"
    cron_schedule:
      minute:   '0'
      hour:     '*/1'
      monthday: '*'
      month:    '*'
      weekday:  '*'
    auto_alias: true                    # Flag to generate the site alias automatically. Defaults to true. (not yet implemented)
    site_aliases:                       # Specific values to enter into the sites.php file. These will be added after any automatically generated values. The ``sites_subdir`` value is used as the directory value by default.
      mysitecom:                       # Generates: $sites['8080.mysite.com'] = 'default';
        domain: 'mysite.com'
        port: 8080
      myothersitecom:                  # Generates: $sites['myothersite.com.subpath'] = 'default';
        domain: 'myothersite.com'
        path: 'subpath'
    auto_drush_alias: true              # Flag to generate the drush alias automatically. Defaults to true. (not yet implemented)
    drush_alias: 'mysite'               # Name to use when generating the drush site alias entry. Defaults to the name generate by Puppet for your site. It is highly recommended you set a value for alias. (not yet implemented)
    additional_settings:                # Array of PHP lines to add to the settings.php file for your site. Note that these values are set after the install.php has been run.
      - '$conf["devel_debug_mail_directory"] = "/path/to/folder";'
      - '$conf["mail_system"]["default-system"] = "DevelMailLog";'
  dropfort:
    profile: 'dropfort_profile'         # This is an install profile which comes with this distribution
    account_name: 'admin'
    account_pass: 'adminpassword'
    account_mail: 'admin@example.com'
    clean_url: true
    db_prefix: ''
    db_su: '<root>'
    db_su_pw: '<pass>'
    db_url: 'mysql://root:pass@127.0.0.1/db'
    locale: '<en_GB>'
    site_mail: 'admin@example.com'
    site_name: 'Site 2 Install'
    sites_subdir: 'default'
    base_url: '<https://app.dropfort.com>'
    keyvalue: 'key=value'               # See drush si documentation for more details
    distro: dropfort
  account:
    profile: 'dropfortl10n_profile'     # This is the install profile we added in the config above
    account_name: 'admin'
    account_pass: 'adminpassword'
    account_mail: 'admin@example.com'
    clean_url: true
    db_prefix: ''
    db_su: '<root>'
    db_su_pw: '<pass>'
    db_url: 'mysql://root:pass@127.0.0.1/db'
    locale: '<en_GB>'
    site_mail: 'admin@example.com'
    site_name: 'Site 2 Install'
    sites_subdir: 'default'
    base_url: '<https://account.dropfort.com>'
    distro: dropfort

drupalsi::profiles:
  dropfortl10n_profile:
    profile: dropfortl10n_profile
    version: 2.0                        # Builds out the full version based on the distro version. In this case it would be 7.x-2.0
    build_type: 'get'
                                        #  Options:
                                        #    'make'  _>  Build the profile using a drush make file. Optionally from a remote file source. See distro_build_args for more details
                                        #    'get' _>  Download the site with drush
                                        #    'git'   _>  Clone the site with Git
                                        #    'local' _>  Profile which is already present. For example the 'standard' install profile in Drupal. Used to generate the dependency tree in Puppet.

    build_location: 'https://updates.dropfort.com/fserver/release_history'
    build_args:                         # Arguments to add to the build_location method. For example with 'get' requests, adds key/value pairs to the URL via querystring parameters. Defaults to ''.
      sitetoken: '134asdfasdf12341234sdasdf'
      core: '7.x'                       # Name of the make file to build the site with or the url of the profile's location.
    distro: dropfort
````