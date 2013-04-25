#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use File::Temp qw(tempfile tmpnam);
use POSIX qw(strftime ttyname);

our $URL = "https://mydifferurl.example/";
our $DEFAULT_DOMAIN = "differ.com";

my $PARAMS = get_params();
submit($PARAMS);

sub get_params {
	my %params;

	for my $param (@ARGV) {
		my ($k, $v) = split /=/, $param;
		$params{$k} = $v;
	}

	if (!keys %params) {
		warn "WARNING: No parameters passed\n";
		warn "USAGE: $0 comment='whatever' username=you\@place.com notify_address=guy\@review.com password=optional parent_diff_id=382382 diff=/home/foo.diff\n";
	}

	$params{comment}        ||= "";
	$params{username}       ||= $ENV{USER};

	if ($params{username} !~ /@/) {
		if (my $domain = $ENV{DIFFER_DOMAIN}) {
			$params{username} .= "\@$domain";
		}
		else {
			$params{username} .= "\@$DEFAULT_DOMAIN";
		}
	}

	$params{notify_address} ||= "";

	if (!$params{notify_address} && $ENV{DIFFER_DEFAULT_NOTIFY}) {
		$params{notify_address} = $ENV{DIFFER_DEFAULT_NOTIFY};
	}

	if ($params{notify_address} && $params{notify_address} !~ /@/) {
		if (my $domain = $ENV{DIFFER_DOMAIN}) {
			$params{username} .= "\@$domain";
		}
		else {
			$params{username} .= "\@$DEFAULT_DOMAIN";
		}
	}

	$params{password}       ||= "";
	$params{parent_diff_id}        ||= "";

	if (!$params{diff}) {
		my ($fh, $filename) = tempfile();

		print $fh <STDIN>;
		close $fh;

		$params{diff} = $filename;
	}

	if (!$params{comment}) {
		$params{comment} = get_comment();
	}

	return \%params;
}

sub get_comment {
	my $file = tmpnam();
	system("vim $file < /dev/tty > /dev/tty");

	if (!-s $file) {
		warn "No comment given";
		return "";
	}

	open my $fh, $file or die "Can't open comment file: $!";
	
	return join "", <$fh>;
}

sub submit {
	my $params = shift;
	my $agent = LWP::UserAgent->new();

	$params->{diff} = [$params->{diff}];

	$agent->timeout(60);
	$agent->ssl_opts('verify_hostname', 0); # Ignore SSL errors
	my $res = $agent->post(
		$URL,
		[], 
		Content_Type => "multipart/form-data",
		Content => [%$params]
	);

	if ($res->is_error) {
		warn "An error has occurred";
		print $res->error_as_HTML . "\n";
	}
	else {
		my $url = $res->content;
		print "$url\n";

		open my $log, ">>", "$ENV{HOME}/.review_log"
			or die $!;
		my $now = strftime "%F %T", localtime;
		print $log "$now\t$url\t$$params{comment}\n";
	}
}
