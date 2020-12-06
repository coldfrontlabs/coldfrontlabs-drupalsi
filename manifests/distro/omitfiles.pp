# Remove files
define drupalsi::distro::omitfiles() {
  # Since I can't loop or pass other arguments, we have to build data into the string
  # Not ideal but it works. If anyone has a better idea please submit a patch
  $parts = split($name, '\|\|')

  validate_absolute_path($parts[1])

  file{$parts[1]:
    ensure  => 'absent',
    require => $parts[0],
  }
}
