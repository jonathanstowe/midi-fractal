#!/usr/bin/perl 

use strict;
use warnings;

use MIDI;
use Math::Complex;
use Getopt::Long;


my $mode = 'ionian';
my $octaves = 2;
my $outfile = 'mandelbrot.mid';

my $flatten = 1;

my $min_length = 6;

my $dx = 0.0315;
my $dy = 0.05;

my $base_note = 'E2';

GetOptions(
			'mode=s'	=>	\$mode,
			'octaves=i'	=>	\$octaves,
			'outfile=s'	=>	\$outfile,
			'flatten!'	=>	\$flatten,
			'min_length=i'	=>	\$min_length,
            'base_note=s'	=>	\$base_note,
			'dx=f'			=>	\$dx,
			'dy=f'			=>	\$dy
          );

my %modes = (   
				ionian		=>	[2,2,1,2,2,2,1],
				dorian		=>	[2,1,2,2,2,1,2],
				phrygian	=>	[1,2,2,2,1,2,2],
				lydian		=>	[2,2,2,1,2,2,1],
				mixolydian 	=> 	[2,2,1,2,2,1,2],
				aeolian		=>	[2,1,2,2,1,2,2],
				locrian		=>	[1,2,2,1,2,2,2],
				major		=>	[2,2,1,2,2,2,1],
			);
			

sub modepos2triad
{
	my ( $mode, $root, $pos ) = @_;

	my @notes;

	if (my $mode_scale = $modes{$mode})
	{
		if ( $pos && $pos < 8)
		{
			
		}
	}


	return @notes;
}

sub modepos
{
	my ( $mode, $root, $pos ) = @_;

	
	my $note;

	if (my $mode_scale = $modes{$mode})
	{
		if ( $pos )
		{
			$note = $root;
			if ( $pos > 1 )
			{
				if ($pos > $#{$mode_scale} )
				{
					push @{$mode_scale}, @{$mode_scale};
				}
				$pos = $pos - 2;

				foreach my $off (@{$mode_scale}[0 .. $pos])
				{
					$note = $note + $off;
				}
			}
		}
	}

	return $note;
}
			   
my $test = MIDI::Track->new();
 
$test->new_event('set_tempo', 0, 450_000);

my $base_num = $MIDI::note2number{$base_note};

sub mandelbrot 
{
    my ($z, $c, $max_iter) = @_;

    my $rc = 1;

    for my $iter (1 .. $max_iter) 
	{
        $z = $z * $z + $c;
        if ( abs $z > 2 )
        {
			$rc = $iter;
			last;
		}
    }

	return $rc;
}
 
my $old_note;

for (my $y = 1; $y >= -1; $y -= $dy) 
{
	my $note_length = $min_length;
    for (my $x = -2; $x <= 0.5; $x += $dx)
    {
		my $z = $x + $y * i;
        my $c = $z;
        my $max_iter = $octaves * 8;
        my $note =  modepos($mode, $base_num,mandelbrot($z, $c, $max_iter));

		if ( $flatten )
        {
			if ( defined $old_note)
			{
				if ( $note != $old_note )
				{
        			$test->new_event('note_on' , 0,  1, $old_note, 127);
        			$test->new_event('note_off', $note_length,1,$old_note,127);
					$old_note = $note;
					$note_length = $min_length;
				}
				else
				{
					$note_length += $min_length;
				}
			}
			else
			{
				$old_note = $note;
				$note_length = $min_length;
			}
		}
		else
		{
        	$test->new_event('note_on' , 0,  1, $note, 127);
        	$test->new_event('note_off',  $min_length,  1, $note, 127);
		}
    }
}

my $opus = MIDI::Opus->new(
  { 'format' => 1, 'ticks' => 96, 'tracks' => [ $test ] } );
$opus->write_to_file( $outfile);
