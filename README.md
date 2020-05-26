affycoretools
=============

[![Build Status](https://travis-ci.com/jmacdon/affycoretools.svg?branch=master)](https://travis-ci.com/jmacdon/affycoretools)

Make repetitive analyses of microarray and RNA-Seq data simpler with affycoretools.

  The affycoretools package is primarily intended to make
  analyses of Affymetrix GeneChip data simpler and more
  straightforward. There are any number of packages
  designed for preprocessing or analyzing Affy data, but
  there are not so many that help streamline the analysis
  to help create useful output that can be given to
  collaborators.

  The affycoretools package is also intended to be
  used as a way to do reproducible research, where the
  analysis and documentation are all held in a single file,
  that is then processed by R to create the output data, as
  well as a nicely formatted pdf that documents the
  analysis. The affycoretools package can be used with
  either Sweave or knitr documents, although these days
  knitr is really the way to go.

  In addition, affycoretools can be used with either
  annaffy or ReportingTools to create useful output in HTML
  or text format to share with your collaborators. However,
  ReportingTools is being actively developed and
  maintained, whereas annaffy is not, so the intention is
  to slowly convert all the functions to primarily use
  ReportingTools.
