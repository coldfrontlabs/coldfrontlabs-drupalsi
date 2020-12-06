# Generate list of site aliases in site.php
define drupalsi::site::site_alias(
  $domain,
  $port = undef,
  $path = undef,
  $directory,
  $sites_file
) {

  # Build the site alias entry
  if $port {
    $p = "${port}."
  }

  if $path {
    $pth = ".${path}"
  }

  $parsed_alias = "\$sites['${p}${domain}${pth}'] = '${directory}';"
  file_line{$name:
    ensure  => 'present',
    line    => $parsed_alias,
    require => File[$sites_file],
    path    => $sites_file,
  }
}
