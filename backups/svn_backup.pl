#!/usr/bin/perl -w

use strict;
use Net::Amazon::EC2;
use LWP;

# We want to backup Subversion in a belt and braces manner
# by:
# 1. Snapshotting the EBS vol
# 2. Mounting a spare EBS volume and archiving to that volume
# Should give us good backups in the event of a failure.
# Only thing to note is that nothing is encrypted so access to
# source is only as secure as EC2's access policies.

# We source our EC2 details from another file as I don't want
# my Amazon credentials available on Git
require 'aws_keys.pl';
# Our keys should be in a file like this:
# filename "aws_keys.pl"
# ----------------------------------
# our ($accesskeyid, $secret );
# $accesskeyid = "1234"
# $secret = "4567"
# ----------------------------------
# The file aws_keys.pl gives us the 2 vars above

# Create a connection to AWS:

#my $ec2 = Net::Amazon::EC2->new(
#        AWSAccessKeyId => $accesskeyid, 
#        SecretAccessKey => $secret
#);

# Get our instance ID using perl lwp module.
# All EC2 instances cat get info about themselves
# from a local http call:
# http://169.254.169.254/latest/meta-data/

$instance_id = HTTP::Request->new(GET => 'http://169.254.169.254/latest/meta-data/instance-id');

print "$instance_id\n";

