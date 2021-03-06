% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_mgcv_smooth_1D.R
\name{plot.mgcv.smooth.1D}
\alias{plot.mgcv.smooth.1D}
\title{Plotting one dimensional smooth effects}
\usage{
\method{plot}{mgcv.smooth.1D}(x, n = 100, maxpo = 10000,
  trans = function(.x) {     .x }, unconditional = FALSE,
  seWithMean = FALSE, ...)
}
\arguments{
\item{x}{a smooth effect object.}

\item{n}{number of grid points used to compute main effect and c.i. lines.
For a nice smooth plot this needs to be several times the estimated degrees of
freedom for the smooth.}

\item{maxpo}{maximum number of residuals points that will be used by layers such as
\code{resRug()} and \code{resPoints()}. If number of datapoints > \code{maxpo},
then a subsample of \code{maxpo} points will be taken.}

\item{trans}{monotonic function to apply to the smooth and residuals, before plotting.
Monotonicity is not checked, but default plot limits assume it.}

\item{unconditional}{if \code{TRUE} then the smoothing parameter uncertainty corrected covariance
matrix is used to compute uncertainty bands, if available.
Otherwise the bands treat the smoothing parameters as fixed.}

\item{seWithMean}{if TRUE the component smooths are shown with confidence intervals that
include the uncertainty about the overall mean. If FALSE then the uncertainty
relates purely to the centred smooth itself. Marra and Wood (2012) suggests
that TRUE results in better coverage performance, and this is also suggested
by simulation.}

\item{...}{currently unused.}
}
\value{
An objects of class \code{plotSmooth}.
}
\description{
Plotting one dimensional smooth effects.
}
\examples{
library(mgcViz)
n  <- 1e3
x1 <- rnorm(n)
x2 <- rnorm(n)
dat <- data.frame("x1" = x1, "x2" = x2,
                  "y" = sin(x1) + 0.5 * x2^2 + pmax(x2, 0.2) * rnorm(n))
b <- bam(y ~ s(x1)+s(x2), data = dat, method = "fREML", discrete = TRUE)
b <- getViz(b)

o <- plot( sm(b, 1) ) 

# Plot with fitted effect + rug on both axis
( o <- o + l_fitLine(colour = "red") + 
    l_rug(mapping = aes(x=x, y=y), alpha = 0.8) )

# Add CI lines at 1*sigma and 5*sigma
( o <- o + l_ciLine(mul = 1) + l_ciLine(mul = 5, colour = "blue", linetype = 2) )

# Add partial residuals and change theme
( o + l_points(shape = 19, size = 1, alpha = 0.2) + theme_classic() )

# Get second effect plot
o2 <- plot( sm(b, 2) )

# Plot it with polygon for partial residuals
o2 + l_ciPoly(mul = 5, fill = "light blue") + 
  l_fitLine(linetype = 2, colour = "red")

# Plot is with conditional density of partial residuals
o2 + l_dens(type = "cond", alpha = 0.9)  + 
  l_fitLine(linetype = 2, colour = "red")
}
