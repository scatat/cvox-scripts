#!/usr/bin/perl -w

use strict;
use Net::Amazon::EC2;
use LWP::Simple;

# We want to backup Subversion in a belt and braces manner
# by:
# 1. Snapshotting the EBS vol
# 2. Mounting a spare EBS volume and archiving to that volume
# Should give us good backups in the event of a failure.
# Only thing to note is that nothing is encrypted so access to
# source is only as secure as EC2's access policies.

my $svn_mount = "/opt/svn";

# We source our EC2 details from another file as I don't want
# my Amazon credentials available on Git
# We set the path by making our location a lib:
use lib  '/opt/aws';
use Aws_keys;
# Our keys should be in a file like this:
# filename "/opt/aws/aws_keys.pm"
# ----------------------------------
# package Aws_keys
# use strict;
# use Exporter 'import';
# our @ISA = 'Exporter';
# our ($accesskeyid, $secret );
# our @EXPORT = qw($accesskeyid $secret);
# $accesskeyid = "1234";
# $secret = "4567";
# ----------------------------------
# Set perms to only be root readable
# The file aws_keys.pl gives us the 2 vars above

# Create a connection to AWS:

print "sanity: $accesskeyid, $secret\n";

my $ec2 = Net::Amazon::EC2->new(
        AWSAccessKeyId =>  "$accesskeyid", 
        SecretAccessKey => "$secret",
	region => "eu-west-1"
) || die "unable to make connection\n";


# Get our instance ID using perl lwp module.
# All EC2 instances cat get info about themselves
# from a local http call:
# http://169.254.169.254/latest/meta-data/
my $url = 'http://169.254.169.254/latest/meta-data/instance-id ';
my $instance_id = get($url);
if (!defined $instance_id) {
    die "failed to fetch URL $url";
}

# Scan fstab for the SVN mount point as defined in our var
# We want to confirm it's xfs and get the device info
# so we can search for it whene we get our instance info

# Let's get some info on the host and we can then confirm our
# ebs volume we want to snapshot
my $instance_info = $ec2->describe_instances(InstanceId => "$instance_id"); 

# Our first backup task is to snapshot our xfs volume.
# 1. We freeze the volume

# 2. We snapshot the volume

# 3. We mount the backup EBS volume
# 4. We tar and gzip the svn repo into the EBS volume
# 5. We unfreeze the volume 
# We email admin with the results of the backup

