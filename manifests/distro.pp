# Defines a drupalsi::distro resource

# Defines a drupalsi::distro resource

define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 7,
                         $distro_root = '/var/www/html',
                         $distro_build_type = 'get',
                         $distro_build_location = 'https://updates.drupal.org/release-history',
                         $distro_build_args = {},
                         $profiles = {},
                         $sites = {}
                         ) {

  # Check if the distro is already there
  $onlyf = "test ! -f ${distro_root}/${name}/index.php"

  # Download the distro and place it in the proper location
  # Ex: drush dl drupal-7.28 --destination=/var/www/html/drupal -y

  if ($distro_build_type == 'get') {

    # Set some defaults for the GET build type
    if !$distro_build_location {
      $distro_build_location = ''
    }

    drush::dl {"drush-dl-${name}-${distribution}-${api_version}":
      source => $distro_build_location,
      destination => $distro_root,
      project_name => $distribution,
      default_major => $api_version,
      drupal_project_rename => $name,
      onlyif => $onlyif,
    }
  }
  elsif ($distro_build_type == 'make') {
    drush::make {"drush-make-${name}-${distribution}-${api_version}":
      makefile => $makefile,
      build_path => "${distro_root}/${name}",
      concurrency => $distro_build_args[concurrency],
      contrib_destination => $distro_build_args[contrib_destination],
      dev => $distro_build_args[dev],
      download_mechanism => $distro_build_args[download_mechanism],
      force_complete => $distro_build_args[force_complete],
      ignore_checksums => $distro_build_args[ignore_checksums],
      libraries => $distro_build_args[libraries],
      make_update_default_url => $distro_build_args[make_update_default_url],
      md5 => $distro_build_args[md5],
      no_cache => $distro_build_args[no_cache],
      no_clean => $distro_build_args[no_clean],
      no_core => $distro_build_args[no_core],
      no_gitinfofile => $distro_build_args[no_gitinfofile],
      no_patch_txt => $distro_build_args[no_patch_txt],
      prepare_install => $distro_build_args[prepare_install],
      projects => $distro_build_args[projects],
      source => $distro_build_args[source],
      tar => $distro_build_args[tar],
      test => $distro_build_args[test],
      translations => $distro_build_args[translations],
      version => $distro_build_args[version],
      working_copy => $distro_build_args[working_copy],
      onlyif => $onlyif
    }
  }

  # Additional settings for creating profiles and sites
  $distro_settings = {
    'site_root' => "${distro_root}/${name}"
  }

  #create_resources('drupalsi::profile', ${distro::profiles})
  create_resources('drupalsi::site', $sites, $distro_settings)


  # Generate the sites.php file for all sites installed on this distro
}
