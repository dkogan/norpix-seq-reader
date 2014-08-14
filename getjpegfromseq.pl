#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Euclid;
use feature ':5.10';
use autodie;
use Sys::Mmap;

my $fd;
open $fd, '<', $ARGV{'<input>'};

my $input;
mmap( $input, 0, PROT_READ, MAP_SHARED, $fd, 0 )
  or die "Couldn't mmap the input file";

my $jpeg_start = pack('(H2)*', qw(ff d8 ff e0 00 10 4a 46 49 46));

my $pos = index($input, $jpeg_start, 0);
if($pos < 0)
{
    die "Couldn't find any JPEG frames in $ARGV{'<input>'}";
}

my $iframe = 0;

while( $ARGV{'-n'} ? $iframe < $ARGV{'-n'} : 1)
{
    my $pos_next = index($input, $jpeg_start, $pos+1);
    if( $pos_next < 0 )
    {
        # no more matches. This is the last frame
        writeframe( $iframe++, $input, $pos, -1);
        exit;
    }

    writeframe( $iframe++, $input, $pos, $pos_next );
    $pos = $pos_next;
}



sub writeframe
{
    my ($i, $input, $pos0, $pos1) = @_;

    my $filename = sprintf( "frame_%05d.jpg", $i);
    open my $fd_frame, '>', $filename;

    syswrite $fd_frame, $input, $pos1 > 0 ? $pos1-$pos0 : 1_000_000_000, $pos0;
}




__END__

=head1 NAME

getjpegfromseq.pl - extracts JPEG frames from a given .SEQ file

=head1 SYNOPSIS

 # extracts all the frames
 ./getjpegfromseq.pl -n 5 input.seq

 # extracts the first 5 frames
 ./getjpegfromseq.pl -n 5 input.seq

=head1 DESCRIPTION

Reads a .SEQ and outputs JPEGs. This tool is super simple and assumes that the
SEQ is simply a concatenation of JPEG frames

=head1 REQUIRED ARGUMENTS

=over

=item <input>

SEQ file to read the input from

=for Euclid:
  input.type: readable

=back

=head1 OPTIONS

=over

=item -n <nframes>

How many frames to extract. If omitted, all the frames are extracted

=for Euclid:
  nframes.type: integer, nframes > 0

=back

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>
