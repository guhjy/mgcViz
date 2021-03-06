% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotRGL_mgcv_smooth_2D.R
\name{plotRGL.mgcv.smooth.2D}
\alias{plotRGL.mgcv.smooth.2D}
\title{Visualizing 2D smooth effects in 3D (interactively)}
\usage{
\method{plotRGL}{mgcv.smooth.2D}(o, se = TRUE, n = 40, residuals = FALSE,
  type = "auto", maxpo = 1000, too.far = 0, xlab = NULL, ylab = NULL,
  main = NULL, xlim = NULL, ylim = NULL, se.mult = 1, shift = 0,
  trans = function(.x) {     .x }, seWithMean = FALSE,
  unconditional = FALSE, ...)
}
\description{
XXX
}
\examples{
# Example 1: taken from ?mgcv::te, shows how tensor pruduct deals nicely with 
# badly scaled covariates (range of x 5\% of range of z )
library(mgcViz)

# Simulate some data
test1 <- function(x,z,sx=0.3,sz=0.4) { 
  x <- x*20
  (pi**sx*sz)*(1.2*exp(-(x-0.2)^2/sx^2-(z-0.3)^2/sz^2)+
                 0.8*exp(-(x-0.7)^2/sx^2-(z-0.8)^2/sz^2))
}
n <- 500
old.par <- par(mfrow=c(2,2))
x <- runif(n)/20;z <- runif(n);
xs <- seq(0,1,length=30)/20;zs <- seq(0,1,length=30)
pr <- data.frame(x=rep(xs,30),z=rep(zs,rep(30,30)))
truth <- matrix(test1(pr$x,pr$z),30,30)
f <- test1(x,z)
y <- f + rnorm(n)*0.2

# Fit with t.p.r.s. basis and plot
b1 <- gam(y~s(x,z))
plotRGL(sm(getViz(b1), 1))

rgl.close() # Close

# Fit with tensor products basis and plot (with residuals)
b2 <- gam(y~te(x,z))
plotRGL(sm(getViz(b2), 1), residuals = TRUE)

# We can still work on the plot, for instance change the aspect ratio
library(rgl)
aspect3d(1, 2, 1)

rgl.close() # Close
}
