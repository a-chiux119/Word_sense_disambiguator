# Word_sense_disambiguator
#DESCRIPTION OF TRAIN.PERL:
 This program looks at several instances of sentences from a training
file (train.perl). Each instance
contains a usage of a particular homonym (the homonyms will be
 marked <head> HOMONYM </head>. For the purposes of this assignment,
 the homonyms can have only one of two senses (meanings). We're going to look at the homonym's
collocates. Based on the frequencies with which a sense is related
 to the collocates, we're going to create a ranked list of contexts
 (features). Each feature will receive a score based on the
 confidence with which we can say that feature will result in a
 particular sense assignment. We then print out this feature
 "decision list" for future use.

 TO RUN TRAIN.PERL:  perl decision-list-train.perl somefile-train.txt > somefile-decision-list.txt
 
 
 #DESCRIPTION of TEST.PERL:
 This program assigns meaning to homonyms based on a provided
 "decision-list" (see decision-list-train.perl). Given some test
 data, this program collects the homonym's "features" (collocates)
 and compares them against a ranked decision list. If a feature
 matches with a decision-list feature, the sense from the
 decision-list is assigned to the homonym. If no match is found,
 assign a default sense.

 TO RUN TEST.PERL:  perl decision-list-test.perl some-decision-list.txt some-test.txt > somefile-answers.txt
 
 # DESCRIPTION OF EVAL.PERL: 
 This program takes a test answer file and a "gold
 standard" file and compares them. These files are word sense
 disambiguation assignment files. Each time a test word X is
 incorrectly assigned as Y, it keeps track of the number of X->Y
 errors and prints a confusion matrix showing this number, as well as
 the accuracy of the test file.

 TO RUN EVAL.PERL: > perl decision-list-eval.perl some-key.txt some-answers.txt
