# Defines a drupalsi::distro resource
define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 7,
                         $distro_root = '/var/www/html',
                         $distro_build_type = 'get',
                         $distro_build_location = 'https://updates.drupal.org/release-history',
                         $distro_build_args = {},
                         $omit_files = {}
                         )
{
  include drush

  # Steps:
  # 1. Check if the distro is already there
  # 2. Download the distro and place it in the proper location

  $buildname = md5("${distribution}-${api_version}-${distro_build_type}-${distro_root}-${distro_build_location}")

  if ($distro_build_type == 'get') {

    # Set some defaults for the GET build type
    if !$distro_build_location {
      $distro_build_location = ''
    }

    drush::dl {"drush-dl-${buildname}":
      source => $distro_build_location,
      destination => $distro_root,
      project_name => $distribution,
      default_major => $api_version,
      drupal_project_rename => $name,
      onlyif => "test ! -f ${distro_root}/${name}/index.php",
    }
    $buildaction = "Drush::Dl[drush-dl-${buildname}]"

    file {"${distro_root}/${name}/sites/sites.php":
      ensure => 'present',
      require => Drush::Dl["drush-dl-${buildname}"],
      content => template('drupalsi/sites.php.erb'),
      mode => '0644',
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

    drush::make {"drush-make-${buildname}":
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
      dropfort_userauth_token => $distro_build_args[dropfort_userauth_token],
      dropfort_url => $distro_build_args[dropfort_url],
    }
    $buildaction = "Drush::Make[drush-make-${buildname}]"


    # Generate the sites.php file for use with all sites installed on this distro
    file {"${distro_root}/${name}/sites/sites.php":
      ensure => 'present',
      require => Drush::Make["drush-make-${buildname}"],
      content => template('drupalsi/sites.php.erb'),
      mode => '0644',
    }

  }


  if !empty($omit_files) {
    # See below why we're doing this
    $omitfiles = prefix($omit_files, "${buildaction}||${distro_root}/${name}/")
    drupalsi::distro::omitfiles{$omitfiles:}
  }
}

# Remove files
define drupalsi::distro::omitfiles() {
  # Since I can't loop or pass other arguments, we have to build data into the string
  # Not ideal but it works. If anyone has a better idea please submit a patch
  $parts = split($name, "\|\|")

  notify {"Removing file ${parts[1]} from Drupal distribution.":}

  validate_absolute_path($parts[1])

  file{$parts[1]:
    ensure => 'absent',
    require => $parts[0],
  }
}
