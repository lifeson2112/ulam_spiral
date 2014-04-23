#!/usr/bin/perl

use strict;
use warnings;

use CGI::Ex::Dump qw(debug);
use Image::Magick;

my $p = bless {} , __PACKAGE__;

$p->main();
exit;


sub main {
    my $self = shift;
    #right now size is merely the amount of steps
    my $spiral = Spiral->new({steps=>'400',pixel_size=>1, spacing=>0, ulam=>1});
    $spiral->draw_spiral;
    $spiral->print_spiral;
}


{
    package Spiral;

    use CGI::Ex::Dump qw(debug);

    sub new {
        my $class = shift;
        my $args = shift;
        my $root = $args->{'steps'} 
            * ($args->{'pixel_size'}||1) 
            * ($args->{'spacing'}||1); 
#        + $args->{'pixel_size'} * ($args->{'pixel_size'} * .08) ;
        my $size = "${root}x${root}";
        #start at center
        $args->{'current_point'} = [$root/2,$root/2];
        $args->{'max_pixels'} = ($args->{'steps'} + 1) * ($args->{'steps'} + 1); 
        $args->{'spacing'} ||= 1;
        $args->{'prime_color'} ||= '000';
        $args->{'unprime_color'} ||= '999';
        $args->{'img_obj'} = Image::Magick->new(size => $size);
        return bless {%$args},$class;    
    }

    sub draw_spiral {
        my $self = shift;
        my $args = shift;

        my $steps = $self->{'steps'};
        my $pixel_size = $self->{'pixel_size'};
        # create white canvas
        $self->{'img_obj'}->Read('xc:white');

        $self->{'numpixels'} = 0;
        for(my $i=1; $i <= $steps; $i++){
            my @dirs = $i % 2 ? ("right","down") : ("left","up");
            my $m1 = $dirs[0];
            my $m2 = $dirs[1];
            $self->$m1({interval=>$i});
            $self->$m2({interval=>$i});
        }

        my $x = $self->{'current_point'}->[0];
        my $y = $self->{'current_point'}->[1];
        my $tox = $self->{'current_point'}->[0]+$pixel_size;
        my $toy = $self->{'current_point'}->[1];
        $self->{'current_point'} = [$tox,$toy];
        $self->{'img_obj'}->Draw(primitive=>'line',points=>"$x,$y $tox,$toy",stroke=>'red', strokewidth=>$pixel_size);
    }

    sub print_spiral {
        my $self = shift;
        my $args = shift;

        $self->{'img_obj'}->Write('test.png');
        $self->{'img_obj'}->Write('test.mvg');
        $self->{'img_obj'}->Write('win:');
    }

    sub right {
        my $self = shift;
        my $args = shift;
        $self->draw_relative_line({add=>[$self->{'spacing'},0], %$args});
    }

    sub down {
        my $self = shift;
        my $args = shift;
        $self->draw_relative_line({add=>[0,$self->{'spacing'}], %$args});
    }

    sub left {
        my $self = shift;
        my $args = shift;
        $self->draw_relative_line({add=>[-$self->{'spacing'},0], %$args});
    }

    sub up {
        my $self = shift;
        my $args = shift;
        $self->draw_relative_line({add=>[0,-$self->{'spacing'}], %$args});
    }

    sub draw_relative_line {
        my $self = shift;
        my $args = shift;
        my ($addx,$addy) = @{$args->{'add'}};
        my $pixel_size = $self->{'pixel_size'};
        my $interval = $args->{'interval'} ;
        while($interval--) {
            my $x = $self->{'current_point'}->[0];
            my $y = $self->{'current_point'}->[1];
            my $tox = $self->{'current_point'}->[0] + $addx * $pixel_size;
            my $toy = $self->{'current_point'}->[1] + $addy * $pixel_size;

            #can do really cool stuff here by adding numbers to x and y. basically makes spiral follow a line
            $self->{'current_point'} = [$tox,$toy];

            $self->{'numpixels'}++;

            my $hex;
            if($self->{'ulam'}){
                $hex = $self->is_prime($self->{'numpixels'}) ? $self->{'prime_color'} : $self->{'unprime_color'};
            } else {
                $hex = sprintf("0x%x",$self->{'numpixels'});
                $hex =~ s/0x//g;
                if(scalar(split('',$hex)) < 3) {
                    $hex = "0$hex";
                }
            }

            $self->{'img_obj'}->Draw(primitive=>'line',points=>"$x,$y $tox,$toy",stroke=>"#$hex", strokewidth=>$pixel_size);
        }
    }

    sub is_prime {
        my $self = shift;
        my $num = shift;
        return $self->all_primes($self->{'max_pixels'})->{$num};
    }

    # Using Sieve of Eratosthenes
    sub all_primes {
        my $self = shift;
        my $max = shift;

        return $self->{'primes'} if $self->{'primes'};

        $self->{'primes'} = {map{$_ => 1} (1..$max)};
        foreach my $num (2..$max){
            foreach($self->factors($num,$max)){
                next if $_ <= 3 ;
                delete $self->{'primes'}->{$_};
            }
        }
        return $self->{'primes'};
    }

    sub factors {
        my $self = shift;
        my $base = shift;
        my $max = shift;
        my @factors;
        my $count = 0;
        $count = $base;
        foreach(2..$max){
            $count = $base + $count;
            last if $count > $max;
            push @factors, $count;
        }
        return @factors;
    }


    1;
}


