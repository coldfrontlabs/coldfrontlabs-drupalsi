# Defines a drupalsi::distro resource
define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 8,
                         $distro_root = '/var/www/html',
                         $distro_build_type = 'composer',
                         $distro_build_location = 'https://updates.drupal.org/release-history', # deprecated.
                         $distro_build_args = {},
                         $omit_files = {}
                         )
{
  include ::drush

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
    exec {"composer-require-drush-${buildname}":
      command => "composer require drush/drush",
      cwd => "${distro_root}/${name}",
       path => ['/usr/local/bin', '/usr/bin'],
       subscribe   => Exec["composer-install-drush-${buildname}"],
       refreshonly => true,
    }
  }
  elsif ($distro_build_type == 'git') {
    include ::git
    if has_key($distro_build_args, 'git_branch') {
      $branch = join([ "-b ", '"', $distro_build_args['git_branch'], '"'])
    } else {
      $branch = ""
    }

    # @todo change to use vcsrepo puppet module.
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
