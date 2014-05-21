# Defines a drupalsi::distro resource

# Defines a drupalsi::distro resource

define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 7,
                         $distro_root = '/var/www/html',
                         $distro_build_type = 'get',
                         $distro_build_location = 'https://updates.drupal.org/release-history',
                         $distro_build_args = {},
                         )
{
  include drush

  # Steps:
  # 1. Check if the distro is already there
  # 2. Download the distro and place it in the proper location

  if ($distro_build_type == 'drush') {

    # Set some defaults for the GET build type
    if !$distro_build_location {
      $distro_build_location = ''
    }

    drush::dl {"drush-dl-${name}":
      source => $distro_build_location,
      destination => $distro_root,
      project_name => $distribution,
      default_major => $api_version,
      drupal_project_rename => $name,
      onlyif => "test ! -f ${distro_root}/${name}/index.php",
    }
  }
  elsif ($distro_build_type == 'make') {
    if $distro_build_args['url'] {
      if $distro_build_args['url_args'] {
        $path = "${distro_build_args['url']}?${distro_build_args[url_args]}"
      }
      else {
        $path = "${distro_build_args['url']}"
      }
    }
    else {
      $path = $distro_build_location
    }

    drush::make {"drush-make-${name}":
      makefile => "$path",
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
    }
  }

  # Generate the sites.php file for all sites installed on this distro
}
