# Word_sense_disambiguator
DESCRIPTION:
# This program looks at several instances of sentences from a training
# file (train.perl). Each instance
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
# TO RUN TRAIN.PERL:  perl decision-list-train.perl somefile-train.txt > somefile-decision-list.txt
