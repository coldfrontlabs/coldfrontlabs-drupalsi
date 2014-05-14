# @todo change to check drupal site install, not drush
Facter.add('drupalsiteinstalled') do
  setcode do
    # @todo perhaps use drush @alias status?
    # or drush --root='/var/www/html/drupal' --uri='https://example.com' status or something
    if File.exist? "/usr/local/bin/drush"
      'installed'
    else
      'not-installed'
    end
  end
end