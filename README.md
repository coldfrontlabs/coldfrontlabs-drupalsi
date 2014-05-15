Drupal Site Install
===================

This module manages the installation of a Drupal site. It only cares for the installation task.
Managing updates and code changes are the responsibility of the Drupal site itself.
This module only installs a Drupal site if it does not currently exist.

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
drupalsi:
  drupal:                               # Name of the distribution installation
    distribution: drupal-7.28           # Specify a distribution (e.g. commerce_kickstart, wetkit). Defaults to 'drupal'. Include the version optionally.
    core: 7.x                           # Specify which core API version (e.g. 6.x, 7.x, 8.x). Defaults to '7.x'
    distro_root: '/var/www/html'        # Full path to your Drupal root directory. This will create your site root folder at '/var/www/html/<distroname>'
    sites:
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
        sites_subdir: '<directory_name>'
        base_url: '<https://example.com>'

  dropfort:
    distribution: dropfort                  # Specify a distribution (e.g. commerce_kickstart, wetkit). Defaults to 'drupal'
    core: 7.x                               # Specify which core API version (e.g. 6.x, 7.x, 8.x). Defaults to '7.x'
    distro_version: 1.0                     # Specify a version. Defaults to the latest stable
    distro_build_location: 'dropfort.make'  # Project download URL for your distribution. Defaults to https://update.drupal.org/release_history
                                            # Name of the make file to build the site with or the url of the distro's location.
    distro_build_type: 'make'
                                            #  Options:
                                            #    'make'  _>  Build the site using a drush make file
                                            #    'svn'   _>  Checkout the site with Subversion
                                            #    'git'   _>  Clone the site with Git
                                            #    'get'   _>  Download the Drupal distribution with an HTTP GET request
    distro_root: '/var/www/html'            # Full path to your distro root directory. In this case would create '/var/www/html/dropfort'.
    distro_build_args:                      # Arguments to add to the build_location method. For example with 'get' requests, adds key/value pairs to the URL via querystring parameters. Defaults to ''.
      sitetoken: '134asdfasdf12341234sdasdf'
      core: '7.x'
    profiles:
      dropfortl10n_profile:
        profile: dropfortl10n_profile
        version: 2.0                        # Builds out the full version based on the distro version. In this case it would be 7.x-2.0
        build_type: 'get'
                                            #  Options:
                                            #    'make'  _>  Build the site using a drush make file
                                            #    'svn'   _>  Checkout the site with Subversion
                                            #    'git'   _>  Clone the site with Git
                                            #    'get'   _>  Download the Drupal distribution with an HTTP GET request

        build_location: 'https://updates.dropfort.com/fserver/release_history'
        build_args:                         # Arguments to add to the build_location method. For example with 'get' requests, adds key/value pairs to the URL via querystring parameters. Defaults to ''.
          sitetoken: '134asdfasdf12341234sdasdf'
          core: '7.x'                       # Name of the make file to build the site with or the url of the profile's location:

    sites:
      default:
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
        sites_subdir: 'site2'
        base_url: '<https://app.dropfort.com>'
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
        sites_subdir: 'site2'
        base_url: '<https://account.dropfort.com>'