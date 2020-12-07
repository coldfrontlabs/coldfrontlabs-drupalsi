# Generate list of site aliases in site.php
define drupalsi::site::site_alias(
  String $directory,
  String $target,
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
    content => $parsed_alias,
    target  => $target,
    order   => '10'
  }
}
