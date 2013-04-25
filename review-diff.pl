#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use File::Temp qw(tempfile);
use POSIX qw(strftime);

our $URL = "https://mydifferurl.example";
my $EMAIL = shift or die "Usage: $0 email diff_id\n";
my $ID = shift or die "Usage: $0 email diff_id\n";

my $agent = LWP::UserAgent->new();
$agent->timeout(60);

my $res = $agent->get("$URL/show/$ID");

if ($res->is_error) {
	warn "An error has occurred";
	print $res->error_as_HTML . "\n";
}
else {
	my ($fh, $filename) = tempfile();
	print $fh $res->content;
	close $fh;

	system("vim $filename");

	my @comments = get_comments($filename);

	for my $comment (@comments) {
		my $res = $agent->post(
			"$URL/save_comment",
			[],
			Content => [
				diff_id => $ID,
				username => $EMAIL,
				%$comment
			]
		);

		if ($res->is_error) {
			print $res->error_as_HTML;
		}
		else {
			print $res->content, "\n";
		}
	}
}

sub get_comments {
	my $filename = shift;
	open my $fh, "<", $filename or die "Cannot open $!";
	my @comments;

	while (defined(my $line = <$fh>)) {
		if ($line =~ /^=== \w+ file (.*?)$/) {
			my $current_file = $1;
			$current_file =~ s/'//g;
			my $line_num = 0;

			while (defined(my $diff_line = <$fh>)) {
				$line_num++;

				if ($diff_line =~ /^#/) {
					$diff_line =~ s/^#\s*//;

					push @comments, {
						"file"     => $current_file,
						"line_number" => $line_num,
						"comment"  => $diff_line
					};

					$line_num --;
				}
			}
		}
		else {
			next;
		}
	}

	return @comments;
}
