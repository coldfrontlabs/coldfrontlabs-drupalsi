# Generate Drupal databases file entry.
define drupalsi::site::database(
  String $target,
  String $dbname,
  String $database = 'default',
  String $replica = 'default',
  String $dbuser = '',
  String $dbpass = '',
  String $prefix = '',
  String $dbhost = 'localhost',
  Integer $port = 3306,
  Enum['mysql', 'pgsql', 'sqlite'] $driver = 'mysql',
  String $collation = '',
  Hash $settings = {},
) {

  # Add the database settings to the puppet-only managed settings file.
  concat::fragment {"drupal-database-settings-${name}":
    content => epp('drupalsi/database.php.epp', {
      'dbname'   => $dbname,
      'database' => $database,
      'replica'  => $replica,
      'dbuser'   => $dbuser,
      'dbpass'   => $dbpass,
      'prefix'   => $prefix,
      'dbhost'   => $dbhost,
      'port'     => $port,
      'driver'   => $driver,
    }),
    target  => $target,
    order   => 10,
  }

}
