# Defines a drupalsi::distro resource
define drupalsi::distro (
  $distribution = 'drupal',
  $env = {},
  $api_version = 8,
  $distro_root = '/var/www/html/drupal',
  $distro_docroot = 'web',
  $distro_build_type = 'composer',
  $distro_build_location = 'https://updates.drupal.org/release-history', # deprecated.
  $distro_build_args = {},
  $omit_files = {}, #deprecated
  $owner = 'apache',
) {
  include ::drush

  if  $::osfamily == 'RedHat' {
    $web_user = 'apache'
  }
  elsif $::osfamily == 'Debian' {
    $web_user = 'www-data'
  }

  # Steps:
  # 1. Check if the distro is already there
  # 2. Download the distro and place it in the proper location

  $buildname = md5("${distribution}-${api_version}-${distro_build_type}-${distro_root}-${distro_build_location}-${name}")

  # Drupal 8 always uses Composer.
  if ($distro_build_type == 'composer' or Integer($api_version) >= 8) {
    # Do nothing for now.
    # @todo run composer install or just leave it be?
    exec {"composer-require-cleanenv-${buildname}":
      command     => 'rm -f .env',
      cwd         => $distro_root,
      path        => ['/usr/local/bin', '/usr/bin', '/bin'],
      creates     => "${distro_root}/composer.json",
      environment => ['HOME=/var/www'],
    }
    ~> exec {"composer-install-drupal-${buildname}":
      command     => "composer create-project  --remove-vcs --no-cache --no-interaction drupal/recommended-project ${distro_root}",
      path        => ['/usr/local/bin', '/usr/bin'],
      creates     => "${distro_root}/composer.json",
      user        => $owner,
      environment => ['HOME=/var/www'],
      require     => Class['php'],
    }

    exec {"composer-require-drush-${buildname}":
      command     => 'composer require drush/drush',
      cwd         => $distro_root,
      path        => ['/usr/local/bin', '/usr/bin'],
      subscribe   => Exec["composer-install-drupal-${buildname}"],
      refreshonly => true,
      user        => $owner,
      environment => ['HOME=/var/www'],
    }

  }
  elsif ($distro_build_type == 'git') {
    include ::git
    if has_key($distro_build_args, 'git_branch') {
      $branch = join([ '-b ', '"', $distro_build_args['git_branch'], '"'])
    } else {
      $branch = ''
    }

    # @todo change to use vcsrepo puppet module.
    exec {"git-clone-${buildname}":
      command => "git clone ${branch} ${distro_build_location} ${distro_root}/${name}",
      creates => $distro_root,
      path    => ['/usr/bin', '/usr/sbin'],
      require => Class['git'],
      onlyif  => "test ! -d ${distro_root}",
      timeout => 1800,
    }

    $buildaction = "Exec[git-clone-${buildname}]"

    # Ensure the file is there even if it's blank.
    file {"${distro_root}/sites/sites.php":
      ensure  => 'present',
      require => Exec["git-clone-${buildname}"],
      mode    => '0644',
    }
  }

  exec {"create-${buildname}-sites.php":
    creates => "${distro_root}/${distro_docroot}/sites/sites.php",
    command => "/bin/cp ${distro_root}/${distro_docroot}/sites/example.sites.php ${distro_root}/${distro_docroot}/sites/sites.php"
  }

  # Add an env file.
  concat {"${distro_root}/.env":
    ensure_newline => true,
    replace        => false,
    backup         => false,
    order          => 'numeric',
    show_diff      => false,
    group          => $web_user, # @todo use def modififier collector to fix this to webserver user.
    require        => Exec["composer-install-drupal-${buildname}"] #@todo generalize to work with git clone too.
  }

  # Add require env varialbes.
  concat::fragment {"${distro_root}-envvars":
    target  => "${distro_root}/.env",
    content => dotenv($env),
    order   => 1
  }

  concat {"${distro_root}/${distro_docroot}/sites.php":
    ensure         => 'present',
    path           => "${distro_root}/${distro_docroot}/sites/sites.php",
    mode           => '0640',
    ensure_newline => true,
    order          => 'numeric',
    replace        => false,
    backup         => false,
    show_diff      => true,
    group          => $web_user, # @todo use def modififier collector to fix this to webserver user.
    require        => Exec["create-${buildname}-sites.php"],
  }
}

