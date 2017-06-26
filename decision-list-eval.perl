#!usr/bin/perl;
use strict;
use warnings;
use Text::Diff;
#---------------------------------
# DECISION-LIST-EVAL.PERL
# Alexa Chiu
# Dr. Pedersen
# CS 5761 PA 4
# Due: November 17, 2016

# Description: This program takes a test answer file and a "gold
# standard" file and compares them. These files are word sense
# disambiguation assignment files. Each time a test word X is
# incorrectly assigned as Y, it keeps track of the number of X->Y
# errors and prints a confusion matrix showing this number, as well as
# the accuracy of the test file.

# TO RUN: > perl decision-list-eval.perl some-key.txt some-answers.txt

# GENERAL ALGORITHM:
# 1. Build the test and gold data
#    1.1 Find the instance ID's
#    1.2 Find the instance sense

# 2. Compare the files
#    2.1 Note the error counts
#    2.2 Update hits and misses

# 3. Print results
#    3.1 Print the confusion matrix
#    3.2 Print the accuracy of test file
#
#--------------------------------

open GOLDFILE, "<", $ARGV[0] or die $!;
open TESTFILE, "<", $ARGV[1] or die $!;

my $hits = 0;
my $misses = 0;
my @testlines = <TESTFILE>;
my @goldlines = <GOLDFILE>;
my %testData; # {instance ID, sense}
my %goldData; # {instance ID, sense}
my %senseTypes; # {sense, count}
my %confusionMatrix; #{gold, {test, count}}

build_data(%testData,@testlines, %goldData, @goldlines, %senseTypes);

compare_files(%testData, %goldData, $hits, $misses, %confusionMatrix);

print_matrix(%confusionMatrix, %senseTypes);

my $gInstID;
my $gsense;
my $tInstID;
my $tsense;


sub build_data{

    # Build test data
    foreach my $testline (@testlines){
        # Get the test's instance ID
        $testline =~ /instance ="(.+)"\s/;
        $tInstID = $1;
        #print "$tInstID\n";

        # Get the test's senseid
        $testline =~ /senseid="(.+)"/;
        $tsense = $1;
        #print "$tsense\n";

        # Add to %testData
        $testData{$tInstID} = $tsense;
        #print "$testData{$tInstID}\n";
    }

    # Build gold data
    foreach my $goldline (@goldlines){
        # Get gold's instance ID
        $goldline =~ /instance="(.+)"\s/;
        $gInstID = $1;
        #print "$gInstID\n";

        # Get gold's senseid
        $goldline =~ /senseid="(.+)"\/>/;
        $gsense = $1;
        #print "$gsense\n";

        # Add to %goldData
        $goldData{$gInstID} = $gsense;

        # Collect the senseid types
        if(exists $senseTypes{$gsense}){}
        else{$senseTypes{$gsense} = 1;}
    }
}

sub compare_files{
    foreach my $testID (keys %testData){

        # get the test sense and gold sense and compare them
        my $testSense = $testData{$testID};
        my $goldSense = $goldData{$testID};

        if($testSense eq $goldSense){$hits++;}
        else{
            # Bad test assignment. Add this to confusion matrix
            $misses++;
            if(exists $confusionMatrix{$goldSense}){
                if(exists $confusionMatrix{$goldSense}{$testSense}){
                    $confusionMatrix{$goldSense}{$testSense}++;
                }
                else{$confusionMatrix{$goldSense}{$testSense} = 1;}
            }
            else{$confusionMatrix{$goldSense}{$testSense} = 1;}
        }
    }
}

sub print_matrix{
    #print top row
    foreach my $g (keys %senseTypes){
        print "          $g              ";
    }
    print
        "\n____________________________________________________________";

    #print the number of times the correct sense (g) was incorrectly
    #tagged with (t)
    foreach my $g (keys %confusionMatrix){
        print "\n\n";
        print "$g";
        foreach my $t (keys %senseTypes){
            if(exists $confusionMatrix{$g}{$t}){
                print "     $confusionMatrix{$g}{$t}        ";
            }
            else{ print "                                 ";  }
        }
    }
    print "\n______________________________________________________________\n\n";
}


##################################################################################################
print "MISSES: $misses\n";
print "Accuracy: ".(($#goldlines -
                              $misses)/$#goldlines)*100;
print "\n";

close TESTFILE or die $!;
close GOLDFILE or die $!;

