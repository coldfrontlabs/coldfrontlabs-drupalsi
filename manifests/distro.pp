# Defines a drupalsi::distro resource
define drupalsi::distro ($distribution = 'drupal',
                         $api_version = 8,
                         $distro_root = '/var/www/html/drupal',
                         $distro_build_type = 'composer',
                         $distro_build_location = 'https://updates.drupal.org/release-history', # deprecated.
                         $distro_build_args = {},
                         $omit_files = {} #deprecated.
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
    exec {"composer-install-drupal-${buildname}":
       command => "composer create-project drupal/recommended-project ${name} -y",
       cwd => $distro_root,
       path => ['/usr/local/bin', '/usr/bin'],
       creates => $distro_root,
    }
    exec {"composer-require-drush-${buildname}":
      command => "composer require drush/drush",
      cwd => $distro_root,
       path => ['/usr/local/bin', '/usr/bin'],
       subscribe   => Exec["composer-install-drupal-${buildname}"],
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
      creates => $distro_root,
      path => ["/usr/bin", "/usr/sbin"],
      require => Class['git'],
      onlyif => "test ! -d ${distro_root}",
      timeout => 1800,
    }

    $buildaction = "Exec[git-clone-${buildname}]"

    # Ensure the file is there even if it's blank.
    file {"${distro_root}/sites/sites.php":
      ensure => 'present',
      require => Exec["git-clone-${buildname}"],
      mode => '0644',
    }
  }
}
