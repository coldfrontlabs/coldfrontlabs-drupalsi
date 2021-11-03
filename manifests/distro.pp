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

  $buildname = md5("${distribution}-${api_version}-${distro_build_type}-${distro_root}-${distro_build_location}-${name}")

  # Drupal 8 always uses Composer.
  if ($distro_build_type == 'composer' or $api_version == 8) {
    # Do nothing for now.
    # @todo run composer install or just leave it be?
    exec {"composer-install-drush-${buildname}":
       command => "composer create-project drupal/recommended-project ${name} -y",
       cwd => $distro_root,
       path => ['/usr/local/bin', '/usr/bin'],
       creates => "${distro_root}/${name}",
    }
  }
  elsif ($distro_build_type == 'get') {

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
      mode => '0640',
    }
  }
  elsif ($distro_build_type == 'git') {
    include git
    if has_key($distro_build_args, 'git_branch') {
      $branch = join([ "-b ", '"', $distro_build_args['git_branch'], '"'])
    } else {
      $branch = ""
    }

    exec {"git-clone-${buildname}":
      command => "git clone ${branch} ${distro_build_location} ${distro_root}/${name}",
      creates => "${distro_root}/${name}/index.php",
      path => ["/usr/bin", "/usr/sbin"],
      require => Class['git'],
      onlyif => "test ! -d ${distro_root}/${name}",
      timeout => 1800,
    }

    $buildaction = "Exec[git-clone-${buildname}]"

    # Ensure the file is there even if it's blank.
    file {"${distro_root}/${name}/sites/sites.php":
      ensure => 'present',
      require => Exec["git-clone-${buildname}"],
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

    # Generate the sites.php file for use with all sites installed on this distro
    file {"${distro_root}/${name}/sites/sites.php":
      ensure => 'present',
      require => Drush::Make["drush-make-${buildname}"],
      content => template('drupalsi/sites.php.erb'),
      mode => '0640',
    }

    $buildaction = "Drush::Make[drush-make-${buildname}]"
  }
  elsif ($distro_build_type == 'archive') {
    # Ensure the hash is there and the proper length
    validate_slength($distro_build_args[hash], 32)

    # Download the file
    if $distro_build_args['url_args'] {
      $path = "${distro_build_location}?${distro_build_args[url_args]}"
    }
    else {
      $path = "${distro_build_location}"
    }

    if $distro_build_args[validate_certificate] {
      $validate = false
    }
    else {
      $validate = true
    }

    wget::fetch {"drupalsi-archive-wget-${buildname}":
      timeout => 0,
      source => $path,
      destination => "/tmp/drush-archive-${buildname}",
      verbose => false,
      nocheckcertificate => $validate,
      source_hash => $distro_build_args[hash],
      user => $distro_build_args[dl_user],
      password => $distro_build_args[dl_pass],
      before => Drush::Arr["drush-arr-${buildname}"],
    }

    drush::arr {"drush-arr-${buildname}":
      filename => "/tmp/drush-archive-${buildname}",
      destination => "${distro_root}/${name}",
      db_prefix => $distro_build_args[db_prefix],
      db_su => $distro_build_args[db_su],
      db_su_pw => $distro_build_args[db_su_pw],
      db_url => $distro_build_args[db_url],
      #overwrite => $distro_build_args[overwrite], Overwrite is ignored on purpose. DrupalSi will not overwrite an existing site.
      tar_options => $distro_build_args[tar_options],
    }

    $buildaction = "Drush::Arr[drush-arr-${buildname}]"

    # Ensure the file is there even if it's blank.
    file {"${distro_root}/${name}/sites/sites.php":
      ensure => 'present',
      require => Drush::Arr["drush-arr-${buildname}"],
      mode => '0640',
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

  validate_absolute_path($parts[1])

  file{$parts[1]:
    ensure => 'absent',
    require => $parts[0],
  }
}
