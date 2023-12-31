% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geneSetTables.R
\name{dataAndHeatmapPage}
\alias{dataAndHeatmapPage}
\title{A function to create an annotated HTML table for all genes in a significant
gene set as well as a heatmap of these data.}
\usage{
dataAndHeatmapPage(
  object,
  fit,
  ind,
  columns = NULL,
  fname,
  heatmap,
  title,
  key = TRUE,
  fitind = NULL,
  affy = TRUE,
  ...
)
}
\arguments{
\item{object}{An ExpressionSet, containing normalized, summarized
gene expression data.}

\item{fit}{An MArrayLM object containing the fitted data.}

\item{ind}{Numeric vector indicating which rows of the
data object to use.}

\item{columns}{Numeric vector indicating which columns of the
data object to use. If \code{NULL}, all columns will be
used.}

\item{fname}{The filename of the resulting output, without the 'html' file
extension.}

\item{heatmap}{Character. The filename of the heatmap to append to the
bottom of the HTML page.}

\item{title}{Title to be placed at the top of the resulting HTML page.}

\item{key}{Character. The filename of the heatmap key to append to the
bottom of the HTML page.}

\item{fitind}{Numeric. Which column of the \code{MArrayLM} object to use for
output in the HTML table.}

\item{affy}{Boolean. Are these Affymetrix arrays? If \code{TRUE}, then links
will be generated to netaffx for the probeset IDs.}

\item{\dots}{Included to allow arbitrary commands to be passed to lower level functions.}
}
\description{
This is intended to be an internal function to \code{runRomer}. It is
documented here only because it may be necessary to pass alternative
arguments to this function from \code{runRomer}.
}
\details{
This function creates an annotation table using \code{probes2table} if an
annotation file is used, otherwise data will be output in a simple HTML
table. A heatmap showing the expression values for all the genes in the gene
set is then placed below this table, along with a key that indicates the
range of the expression values.
}
\author{
James W. MacDonald <jmacdon@u.washington.edu>
}
