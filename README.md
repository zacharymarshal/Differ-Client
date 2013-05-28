Differ-Client
=============

Simple CLI for submitting diffs to a Differ server

Simple Usage
============

Pipe a diff to submit a diff to the differ server


``bzr diff | differ-cli/submit-diff.pl username=rankin.zachary@gmail.com notify_address=rankin.zachary@gmail.com``

INSTALLATION
============

```
 sudo apt-get install libxml-simple-perl  libtest-most-perl libfile-homedir-perl libfile-which-perl libipc-run3-perl libprobe-perl-perl libtest-script-perl libtest-class-perl
 sudo cpan WWW::PivotalTracker Mozilla::CA
```


DEFAULT CONFIG VIA ~/.differ_defaults
=====================================

Each line should consist of "key=value" pairs (no spaces!) that will be used as default arguments to submit-diff.pl

Stuff to include in your defaults:
 * pt_token
 * pt_project_id
 * notify_address
 * username


PIVOTAL TRACKER INTEGRATION
===========================

 * Navigate to your account Profile
 * Create API token
 * set 'pt_token=XXX' and 'pt_project_id=YYY' in ~/.differ_defaults

