#!/usr/bin/env bash

# This script updates ~/.ssh/config with the latest config for ProjectName servers.

set -e

cd "$(dirname "$0")"
cd ..

ssh_config=$(scripts/ssh-config.sh "$@")
begin_marker=$(echo "$ssh_config" | grep '^### BEGIN')
end_marker=$(echo "$ssh_config" | grep '^### END')

perl_code=$(cat <<'PL'
	use strict;

	open CONFIG_R, '<', "$ENV{HOME}/.ssh/config"
		or die "Can't open ~/.ssh/config: $!";
	open CONFIG_W, '>', "$ENV{HOME}/.ssh/config.tmp"
		or die "Can't open ~/.ssh/config.tmp: $!";

	my ($ssh_config, $begin_marker, $end_marker) = @ARGV;
	$ssh_config =~ s/^\s+|\s+$//g;
	$ssh_config .= "\n";
	$begin_marker =~ s/^\s+|\s+$//g;
	$end_marker =~ s/^\s+|\s+$//g;
	my $in_section = 0;
	my $marker_found = 0;

	while (<CONFIG_R>) {
		my $line_trimmed = $_;
		$line_trimmed =~ s/^\s+|\s+$//g;
		if ($line_trimmed eq $begin_marker) {
			if (!$in_section) {
				print CONFIG_W $ssh_config;
				$in_section = 1;
				$marker_found = 1;
			}
		} elsif ($line_trimmed eq $end_marker) {
			$in_section = 0;
		} elsif (!$in_section) {
			print CONFIG_W $_;
		}
	}

	if ($marker_found) {
		say STDERR "~/.ssh/config edited with updated config";
	} elsif (!$marker_found) {
		say STDERR "Existing config marker not found!";
		say STDERR "Adding new config section to end of ~/.ssh/config";
		print CONFIG_W "\n$ssh_config";
	}

	close CONFIG_R;
	close CONFIG_W;
	rename "$ENV{HOME}/.ssh/config.tmp", "$ENV{HOME}/.ssh/config";
PL
)

perl -we "$perl_code" "$ssh_config" "$begin_marker" "$end_marker"
