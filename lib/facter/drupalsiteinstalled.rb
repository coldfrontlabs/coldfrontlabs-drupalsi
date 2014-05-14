# @todo change to check drupal site install, not drush
Facter.add('drupalsiteinstalled') do
  setcode do
    if File.exist? "/usr/local/bin/drush"
      'installed'
    else
      'not-installed'
    end
  end
end
