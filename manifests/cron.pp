<?php

define drupalsi::cron (
	$ensure = "present"
	, $root
	, $uri=""
	, $quiet = $drupalsi::params::cron_quiet
	, $yes = $drupalsi::params::cron_yes
	, $user = $drupalsi::params::cron_user
	, $hours = "*"
	, $minutes = "*/5"
	, $path = $drupalsi::params::cron_path
) {

	# We'll use drush in our cron job.
	include drush
	Class['drush'] -> Drupalsi::Cron["$title"]

	# Build the arguments to the command.
	$root_arg = "--root=$root"

	$uri_arg = $uri ? {
		"" => "",
		default => "--uri='$uri'",
	}

	$quiet_arg = $quiet ? {
		false   => "",
		no      => "",
		""      => "",
		default => "--quiet",
	}

	$yes_arg = $yes ? {
		yes     => "--yes",
		true    => "--yes",
		enable  => "--yes",
		default => "",
	}

	# Build the command strings.
	$command = "drush $quiet_arg $yes_arg $root_arg $uri_arg core-cron"
	$run_command = "/usr/bin/env PATH=$path COLUMNS=72"

	# Create the cron resource.
	cron { "drupalsi-cron-$title" :
	ensure  => $ensure,
	command => "$run_command $command",
	user    => $user,
	hour    => $hours,
	minute  => $minutes,
	}
}