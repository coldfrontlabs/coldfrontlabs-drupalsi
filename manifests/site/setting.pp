# Create a Drupal settings array entry.
define drupalsi::site::setting(
  String $target,
  Variant[Array[String], String] $key,
  Variant[Hash, String] $value,
  Boolean $append = false,
) {

  # @todo support nested key values and values.

  $settingname = md5("${target}-${key}-${value}-${append}")
  $setting = "\$settings['${key}']"

  $content = $append ? {
    true => "${setting}[] = '${value}';",
    false => "${setting} = '${value}';",
  }
  concat::fragment {$settingname:
    target  => $target,
    content => $content,
    order   => 10,
  }
}
