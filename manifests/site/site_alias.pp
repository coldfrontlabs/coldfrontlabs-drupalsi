# Generate list of site aliases in site.php
define drupalsi::site::site_alias(
  String $directory,
  String $sites_file,
  String $domain,
  Variant[Integer, String] $port = '',
  String $path = '',
) {

  # Build the site alias entry
  if !empty($port) {
    $p = "${port}."
  }
  else {
    $p = ''
  }

  if !empty($path) {
    $pth = ".${path}"
  }
  else {
    $pth = ''
  }

  $parsed_alias = "\$sites['${p}${domain}${pth}'] = '${directory}';"

  concat::fragment {$name:
    ensure  => 'present',
    content => $parsed_alias,
    target  => $sites_file,
    order   => '10'
  }
}
