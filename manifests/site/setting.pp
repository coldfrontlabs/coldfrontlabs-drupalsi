# Create a Drupal settings array entry.
define drupalsi::site::setting(
  String $target,
  Variant[Array[String], String] $key,
  Variant[Hash, String] $value,
  Boolean $append = false,
  Integer $order = 10,
  Boolean $raw = false,
) {

  # @todo support nested key values and values.

  $settingname = md5("${target}-${key}-${value}-${append}")
  $setting = "\$settings['${key}']"

  $wrapper = $raw ? {
    true => "",
    false => "'",
  }

  $content = $append ? {
    true => "${setting}[] = ${wrapper}${value}${wrapper};",
    false => "${setting} = ${wrapper}${value}${wrapper};",
  }
  concat::fragment {$settingname:
    target  => $target,
    content => $content,
    order   => $order,
  }
}
