#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use File::Temp qw(tempfile tmpnam);
use POSIX qw(strftime ttyname);

my $PARAMS = get_params();
submit($PARAMS);

sub get_params {
	my %params = get_defaults();

	for my $param (@ARGV) {
		my ($k, $v) = split /=/, $param;
		$params{$k} = $v;
	}

	if (!keys %params) {
		warn "USAGE: $0 comment='whatever' username=you\@place.com notify_address=guy\@review.com password=optional parent_diff_id=382382 diff=/home/foo.diff differ_url=http://differ.foo.com\n";
		warn "OPTIONAL: pt_token=d923klad93 pt_project_id=771987 pt_story_id=500391613323232";
		exit;
	}

	$params{comment}        ||= "";
	$params{username}       ||= $ENV{USER};
	$params{notify_address} ||= "";
	$params{password}       ||= "";
	$params{parent_diff_id} ||= "";

	if (!$params{differ_url}) {
		die "differ_url is required";
	}

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

	$agent->timeout(90);

	if ($params->{differ_url} =~ /^https/) {
		$agent->ssl_opts('verify_hostname', 0); # Ignore SSL errors
	}

	my $res = $agent->post(
		$params->{differ_url},
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

		pt_update_story($params, $url);

		open my $log, ">>", "$ENV{HOME}/.review_log"
			or die $!;
		my $now = strftime "%F %T", localtime;
		print $log "$now\t$url\t$$params{comment}\n";
	}
}

sub pt_update_story {
	my $params = shift;
	my $url    = shift;

	my $token      = $params->{pt_token}      || return;
	my $project_id = $params->{pt_project_id} || return;
	my $story_id   = $params->{pt_story_id}   || return;

	require WWW::PivotalTracker;

	WWW::PivotalTracker::add_note(
		$token,
		$project_id,
		$story_id,
		"Differ Update from $$params{username}: $url\n\n$$params{comment}"
	);
}

sub get_defaults {
	my $file = "$ENV{HOME}/.differ_defaults";
	return unless -e $file;
	my %defaults;

	open my $fh, "<", $file or die $!; 

	while (my $line = <$fh>) {
		chomp $line;
		my ($key, $value) = split /=/, $line;
		$defaults{$key} = $value;
	}   

	return %defaults;
}

