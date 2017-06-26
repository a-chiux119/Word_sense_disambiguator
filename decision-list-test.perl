#!/usr/bin/perl
use strict;
use warnings;

#--------------------------------
# Alexa Chiu
# Dr. Pedersen
# CS 5761 PA4 Word Sense Disambiguation
# Due: November 17, 2016

# DESCRIPTION:
# This program assigns meaning to homonyms based on a provided
# "decision-list" (see decision-list-train.perl). Given some test
# data, this program collects the homonym's "features" (collocates)
# and compares them against a ranked decision list. If a feature
# matches with a decision-list feature, the sense from the
# decision-list is assigned to the homonym. If no match is found,
# assign a default sense.

# TO RUN:  perl decision-list-test.perl some-decision-list.txt some-test.txt > somefile-answers.txt

# GENERAL ALGORITHM
# 1. Get information from the test data
#    1.1 the ambiguity
#    1.2 the context
#    1.3 the instance id

# 2. Compare to decision list and assign a word sense

# 3. print answers

#-------------------------------

my %testData; #{instance id, {ambiguity, [features]}}
my %senseTypes; #{sense, count} collected from testData
my $DEFAULT; # the default sense to assign

open DLIST, "<", $ARGV[0] or die $!;
open TESTFILE, "<", $ARGV[1] or die $!;

$_ = do{local $/; <TESTFILE>;};
my @instances = split(/<\/instance>/);
my $junk = pop(@instances);
#print "instances: $#instances\n";

my @logLs = <DLIST>; # the decision list
#print "dlist: $#logLs\n";

# Enter the training data into the data structure trainingData
build_testData(%testData, @instances);

# Assign senses to training data
assign_sense(%testData, @logLs, %senseTypes, $DEFAULT);


close DLIST or die $!;
close TESTFILE or die $!;

my $ambiguity;
my $instanceID;
my $precontext;
my $postcontext;
my $infix;
my $num = 0;
my $numAm = 0;
my $numSense = 0;
my $numInstID = 0;

sub build_testData{
    my @features;
    foreach my $instance (@instances){
       # $numInst++;

        # get the ambiguous word in this instance
        $instance =~ /<head>(.+)<\/head>/;
        $ambiguity = lc($1);
        $numAm++ if defined $ambiguity;
        #print "$ambiguity\n";

        #----get the unigram preceding <head>
        $instance =~ /.*(\s\b.+\b\s{1})<head>/;
        $precontext = $1;
        $precontext =~ s/\s//;
        $infix = $precontext." ".$ambiguity;
        $precontext = $precontext." ".$ambiguity;
        $num++ if defined $precontext;
        $features[0] = $precontext;

        #----get the unigram succeeding <head>
        $instance =~ /<\/head> (\b\w+|\W+|\d+\b).*<\/s>/;
        $postcontext = $1;
        $postcontext =~ s/\s//;
        $infix = $infix." ".$postcontext;
        $postcontext = $ambiguity." ".$postcontext;
        #print "$postcontext\n";
        $features[1] = $postcontext;
        $features[2] = $infix;

        #get the instance id for this instance
        $instance =~ s/instance id="(.+)"/$1/;
        $instanceID = $1;
        $numInstID++ if defined $instanceID;

        # Put it in the hash
        $testData{$instanceID}{$ambiguity} = [@features];
    }
    #print "number of instances: $numInstID\n";
    #print "number of ambiguities: $numAm\n";
    #print "number of contexts: $num\n";
    #print "number of senses: $numSense\n";

}

sub assign_sense{
    # DETERMINE DEFAULT SENSE
    # For each line in the decision list
    foreach my $i (@logLs){
        # Get the senseid
        $i =~ /senseid: <(.+)\s?>$/;
        my $sense = $1;

        # Add sense to senseTypes
        if(exists $senseTypes{$sense}){
            $senseTypes{$sense}++;
        }
        else{$senseTypes{$sense} = 1;}
    }
    my $freqSense = 0;

    #foreach sense in senseTypes
    foreach my $i (keys %senseTypes){
        if($senseTypes{$i} > $freqSense){$DEFAULT = $i;}
    }
    #print "$DEFAULT\n";


    my $score;
    my $senseid;
    my $dcontext;
    my @tcontext;
    my $foundMatch;

    # for each instance
    foreach my $instance (keys %testData){
        #print $instance;
        $foundMatch = 0;

        foreach my $assignment (@logLs){
            # Get this line's feature
            $assignment =~ /Evidence: <(.+)\s?> --/;
            $dcontext= $1;
            #print "$dcontext\n";

            # Get this line's assigned sense
            $assignment =~ /senseid: <(.+)\s?>$/;
            $senseid = $1;

            my %amb = %{$testData{$instance}};

            # Get the feature vector associated with this instance/ambiguity
            foreach my $word (keys %amb){@tcontext = @{$testData{$instance}{$word}};}

            # convert the feature vector to a hash
            my %blank = map{$_ => 1} @tcontext;

            # If there is an the current decision-list feature is
            # found in the test feature vector
            if(exists $blank{$dcontext}){
                $foundMatch = 1;
                print "<answer instance =\"$instance\" senseid=\"$senseid\"/>\n";
                last;
            }

        }
        #if no match of context, assign a default senseid
        if($foundMatch == 0){print "<answer instance =\"$instance\" senseid=\"$DEFAULT\"/>\n";}
    }
}
