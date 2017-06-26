#!/usr/bin/perl
use strict;
use warnings;

#--------------------------------
# Alexa Chiu
# Dr. Pedersen
# CS 5761 PA4 Word Sense Disambiguation
# Due: November 17, 2016
#
# DESCRIPTION:
# This program looks at several instances of sentences from a training
# file. Each instance
# contains a usage of a particular homonym (the homonyms will be
# marked <head> HOMONYM </head>. For the purposes of this assignment,
# the homonyms can have only one of two senses (meanings). We're going to look at the homonym's
# collocates. Based on the frequencies with which a sense is related
# to the collocates, we're going to create a ranked list of contexts
# (features). Each feature will receive a score based on the
# confidence with which we can say that feature will result in a
# particular sense assignment. We then print out this feature
# "decision list" for future use.
#
# TO RUN:  perl decision-list-train.perl somefile-train.txt > somefile-decision-list.txt

# BASIC ALGORITHM:
# 1. Build the training data from the training file
#    1.1 Identify the ambiguity (I decided to treat plurals as
#        separate ambiguities)

#    1.2 Collect the features. I decided to use both unigrams directly
#        before and after the ambiguity, as well as infixing the ambiguity
#        between them.

# 2. Score the contexts. How many time did a context with the ambiguity produce a
#    particiular sense? There needs to be a count of how many times
#    this happened.

# 3. Sort the contexts by log-liklihood into decision lists

# 4. Print your decision list
#-------------------------------

my %wordsenses; #{word,{context,{senseid, count}}}
my %scores; #{score, {context, sense}}
my %senseTypes;

open TRAININGFILE, "<", $ARGV[0] or die $!;

$_ = do{local $/; <>;};

my @instances = split(/<\/instance>/);
my $junk = pop(@instances);
#print "instances: $#instances\n";

# Enter the training data into the data structure trainingData
build_trainingData(\*TRAININGFILE, %wordsenses, @instances);

# Score the features
score_features(%wordsenses, %scores);

# Print the decision list
print_decision_list(%scores);


close TRAININGFILE or die $!;

my $ambiguity;
my $sense;
my $precontext;
my $postcontext;
my $infixcontext;
my $num = 0;
my $numAm = 0;
my $numSense = 0;
my $numInst = 0;

sub build_trainingData{
    my @features;
    foreach my $instance (@instances){
        $numInst++;
        #print "$instance\n";

        # get the ambiguous word in this instance
        $instance =~ /<head>(.+)<\/head>/;
        $ambiguity = lc($1);
        $numAm++ if defined $ambiguity;
        #print "$ambiguity\n";

        # get the precontext for the ambiguous word

        #----get the unigram preceding <head>
        $instance =~ /.*(\s\b.+\b\s{1})<head>/;
        $precontext = $1;
        $precontext =~ s/\s//;
        $infixcontext = $precontext." ".$ambiguity;
        $precontext = $precontext." ".$ambiguity;
        $num++ if defined $precontext;
        $features[0] = $precontext;

        #----get the unigram succeeding <head>
        $instance =~ /<\/head> (\b\w+|\W+|\d+\b).*<\/s>/;
        $postcontext = $1;
        $postcontext =~ s/\s//;
        $infixcontext = $infixcontext." ".$postcontext;
        $postcontext = $ambiguity." ".$postcontext;
        #print "$postcontext\n";
        $features[1] = $postcontext;
        $features[2] = $infixcontext;

        #get the senseid for this instance
        $instance =~ /senseid="(.+)"/;
        $sense = $1;
        if($instance !~ /senseid="(.+)"/){print "NO SENSE FOUND!\n$instance\n";}
        $numSense++ if defined $sense;

        # get all the sense types found in the training data
        if(exists $senseTypes{$sense}){
            $senseTypes{$sense}++;
        }
        else{
            $senseTypes{$sense} = 1;
        }
        #print "$sense\n";

        # add this instance's information to %wordsenses
        foreach my $feature (@features){
            if(exists $wordsenses{$ambiguity}){
                if(exists $wordsenses{$ambiguity}{$feature}){
                    if(exists $wordsenses{$ambiguity}{$feature}{$sense}){
                        $wordsenses{$ambiguity}{$feature}{$sense}++;
                    }
                    else{ $wordsenses{$ambiguity}{$feature}{$sense} = 1;}
                }
                else{$wordsenses{$ambiguity}{$feature}{$sense} = 1;}
            }
            else{$wordsenses{$ambiguity}{$feature}{$sense} = 1;}
        }
    }
    #print "number of instances: $numInst\n";
    #print "number of ambiguities: $numAm\n";
    #print "number of contexts: $num\n";
    #print "number of senses: $numSense\n";

}

my $toLog; # number to pass to the log2 function

sub score_features{
    # Get all the ambiguities.
    my @ambiguities = keys %wordsenses;
    my @contexts;
    my @senses;

    # Get all the sense types. There should be only 2.
    my @sTypes = keys %senseTypes;
    my $S1 = $sTypes[0]; # sense 1
    my $S2 = $sTypes[1]; # sense 2
    my $pS1; # P(sense 1 | context)
    my $pS2; # P(sense 2 | context)
    my %tmp; #{context, count}
    my $contextSeen; #going to be a count of how many contexts
                     #associated with ambiguity
    my $score;

    # for each ambiguity, score its features.
    foreach my $ambiguity (@ambiguities){

        # Get the feature vector for this ambiguity
        @contexts = keys %{$wordsenses{$ambiguity}};

        # For each feature in the feature vector
        foreach my $context (@contexts){
            $contextSeen = 0;
            $pS1 = 0;
            $pS2 = 0;
            $score = 0;
            $toLog = 0;

            # Get the senses associated with this feature
            @senses = keys %{$wordsenses{$ambiguity}{$context}};
            #print "size of senses--> $#senses\n" if $#senses > 0;

            # For each sense associated with this feature
            foreach my $sense (@senses){
                #update the number of times this contextSeen
                $contextSeen += $wordsenses{$ambiguity}{$context}{$sense};
            }

            # calculate p(s1 | context)
            if(exists $wordsenses{$ambiguity}{$context}{$S1}){
                $pS1 = $wordsenses{$ambiguity}{$context}{$S1} /
                    $contextSeen;
            }
            else{
                # This is to help for if a sense wasn't seen with a
                # feature. Avoid dividing by 0!

                $pS1 = 0.1;
                $pS2 += 0.1;
            }
            # Calculate P(S2 | context)
            if(exists $wordsenses{$ambiguity}{$context}{$S2}){
                $pS2 = $wordsenses{$ambiguity}{$context}{$S2} /
                    $contextSeen;
            }
            else{
                $pS2 = 0.1;
                $pS1 += 0.1;
            }

            $toLog = $pS1/$pS2;
            $score = log2($toLog);

            # Assign a word sense based on a feature's score
            my $senseAss;
            if($score > -1){
                $senseAss = $S1;
            }
            else{
                $senseAss = $S2;
            }

            $score = abs($score);

            #print "p($S1 | $context) = $pS1---";
            #print "p($S2 | $context) = $pS2---";
            #print "SCORE = $score-->$senseAss\n";

            $scores{$score}{$context} = $senseAss;
        }
    }
}



sub log2{ return log($toLog)/log(2);}

sub print_decision_list{
    foreach my $logL (sort {$b <=> $a} keys %scores){
        foreach my $context (keys %{$scores{$logL}}){
            print "LogL: <$logL> --- Evidence: <$context> --- senseid: <$scores{$logL}{$context}>\n";
        }
    }
}
