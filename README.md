
# **mgcViz**: visual tools for Generalized Additive Models

This R package offers visual tools for Generalized Additive Models
(GAMs). Most of the tools provided by `mgcViz` fall in one of the following categories: 

1. Layered smooth effect plots;  

2. Traditional and layered model checks;

The layering system has been implemented by wrapping several `ggplot2` layers and integrating
them with computations specific to GAM models. All methods are meant to work with large datasets ($n \approx 10^7$), by adopting discretization and/or sub-sampling.

## 1 Layered smooth effect plots

Here we start by describing smooth-specific plotting methods and then we move to the new `plot.gam` function, which wraps several plots together.

#### 1.1 Smooth-specific plots

Let's start with a simple example with two smooth effects:

```R
library(mgcViz)
n  <- 1e3
x1 <- rnorm(n)
x2 <- rnorm(n)
dat <- data.frame("x1" = x1, "x2" = x2,
                  "y" = sin(x1) + 0.5 * x2^2 + pmax(x2, 0.2) * rnorm(n))
b <- gam(y ~ s(x1)+s(x2), data = dat, method = "REML")
```

Now we convert the fitted object to the `gamViz` class. Doing this allows to save
quite a lot of time when producing multiple plots using the same fitted GAM model.

```R
b <- getViz(b)
```

We extract the first smooth component using the `sm` function and we plot it.
The resulting `o` object contains, among other things, a `ggplot` object. This
allows us to add several layers.
```R
o <- plot( sm(b, 1) )
( o <- o + l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) )
```

We added only the fitted smooth effect and rugs on the x and y axes. Now we add 
confidence lines at 1 and 5 standard deviations, partial residual points and we
change the theme to `ggplot2::theme_classic`.
```R
o + l_ciLine(mul = 1) + 
    l_ciLine(mul = 5, colour = "blue", linetype = 2) + 
    l_points(shape = 19, size = 1, alpha = 0.1) + 
    theme_classic()
```

Functions such as `l_fitLine` or `l_rug` provide smooth-specific layers. To see all
the layers available for each smooth effect plot we can do:

```R
listLayers(o)
```

Similar methods exist for 2D smooth effect plots, for instance if we fit:

```R
b <- gam(y ~ s(x1, x2), data = dat, method = "REML")
b <- getViz(b)
```

we can do

```R
plot(sm(b, 1)) + l_fitRaster() + l_fitContour() + l_points()
```

This can be converted to an interactive `plotly` plot as follows:
```R
library(plotly)
ggplotly( plot(sm(b, 1)) + l_fitRaster() + l_points() + l_fitContour()  )
```

If needed, we can convert a `gamViz` object back to its original form by doing:
```R
b <- getGam(b)
class(b)
```

#### 1.2 The new `plot.gam` method

The new `plot.gam` function masks `mgcv::plot.gam` when `mgcViz` is loaded. This function
wraps together the plotting methods related to each specific smooth effect, which can 
save time when doing GAM modelling. Consider this model:
```R
dat <- gamSim(1,n=1e3,dist="normal",scale=2)
b <- gam(y~s(x0)+s(x1, x2)+s(x3), data=dat)
```

To plot all the effects we do:
```R
b <- getViz(b)
plot(b)         # Calls print.plotGam()
```

Here `getViz` is not strictly necessary, but converting to a `gamViz` object first saves
time when we need to call `plot.gam` several times. To see all three plots on one page 
we can do:
```R
print(plot(b) + labs(title = NULL), pages = 1)
```

where we have also removed the titles. Notice that `plot.gam` returns an object of class
`plotGam`, which is initially empty. The layers in the previous plots (e.g. the rug and the
confidence interval lines) have been added by `print.plotGam`, which adds some default layers
to empty `plotGam` objects. This can be avoided by setting `addLay = FALSE` in the call to 
`print.plotGam`. A `plotGam` object in considered not empty if we added an object of class
`gamLayer` to it, for instance:
```R
pl <- plot(b) + l_points() + l_fitLine(linetype = 3) + l_fitContour() + 
       l_ciLine(colour = 2) + theme_get() + labs(title = NULL)
print(pl, pages = 1)
pl$empty # FALSE: because we added gamLayers
```

here all the functions starting with `l_` return `gamLayer` objects. Notice that some layers
are not relevant to all smooths. For instance, `l_fitContour` is added only to the second smooth.
The `+.plotGam` method automatically adds each layer only to compatible smooth effect plots.

We can plot individuals effects by using the `select` arguments. For instance:
```R
plot(b, select = 1)
```
where only the default layers are added. Obviously we can have our custom layers instead:
```R
plot(b, select = 1) + l_dens(type = "cond") + l_fitLine() + l_ciLine()
```
where the `l_dens` layer represents the conditional density of the partial residuals.

#### 1.3 Interactive `rgl` smooth effect plots 

`mgcViz` provides tools for generating interactive plots of multidimensional smooths
via the `rgl` R package. Here is an example where we are plotting a 2D slice of 
a 3D smooth effect with confidence intervals:
```R
library(mgcViz)
n <- 500
x <- rnorm(n); y <- rnorm(n); z <- rnorm(n)
ob <- (x-z)^2 + (y-z)^2 + rnorm(n)
b <- gam(ob ~ s(x, y, z))
b <- getViz(b)

plotRGL(sm(b, 1), fix = c("z" = 0), residuals = TRUE)
```

The `fix` argument is used to determine the slice along the z-axis. The plot also shows some residuals (colour-coded depending on sign) that fall close (in term of Euclidean distance) to the selected slice.  
Notice that `plotRGL` is not layered at the moment, and most options need to be specified in the initial function call. But the interactive plot can still be manipulated once the `rgl` window is open,
for instance here we change the aspect ratio:
```R
aspect3d(1, 2, 1)
```

We then close the window using:
```R
rgl.close()
```

## 2 Model checking

#### 2.1 New version of traditional model checks

Most of the model checks provided by `mgcv` are contained in `qq.gam` and `gam.check`.
`mgcViz` provides a new version of `qq.gam` (which masks the one provided by `mgcv`) and
substitutes `gam.check` with the `check.gam` method. 

##### 2.1.1 The new `qq.gam` function

Consider the following model with binomial responses:
```R
set.seed(0)
n.samp <- 400
dat <- gamSim(1,n = n.samp, dist = "binary", scale = .33)
p <- binomial()$linkinv(dat$f) ## binomial p
n <- sample(c(1, 3), n.samp, replace = TRUE) ## binomial n
dat$y <- rbinom(n, n, p)
dat$n <- n
lr.fit <- gam(y/n ~ s(x0) + s(x1) + s(x2) + s(x3)
              , family = binomial, data = dat,
              weights = n, method = "REML")
```

We can get a QQ-plot of the residuals as follows:
```R
qq.gam(lr.fit, method = "simul1", 
       a.qqpoi = list("shape" = 1), 
       a.ablin = list("linetype" = 2))
```
Here `method` determines the method used to compute the QQ-plot, while the arguments
starting with `a.` are lists that will be passed directly to the corresponding `ggplot2`
layer (`geom_point` and `geom_abline` here). We can remove the confidence intervals and 
show all simulated (model-based) QQ-curves as follows:
```R
qq.gam(lr.fit, rep = 20, show.reps = T, CI = "none",
       a.qqpoi = list("shape" = 19),
       a.replin = list("alpha" = 0.2))
```

Importantly, `mgcViz::qq.gam` can handle large datasets by discretizing the QQ-plot before
plotting. For instance, let's increase `n.samp` in the previous example:
```R
set.seed(0)
n.samp <- 50000
dat <- gamSim(1,n=n.samp,dist="binary",scale=.33)
p <- binomial()$linkinv(dat$f) ## binomial p
n <- sample(c(1,3),n.samp,replace=TRUE) ## binomial n
dat$y <- rbinom(n,n,p)
dat$n <- n
lr.fit <- bam(y/n ~ s(x0) + s(x1) + s(x2) + s(x3)
              , family = binomial, data = dat,
              weights = n, method = "fREML", discrete = TRUE)
```

Here the `discrete` argument determines whether the QQ-plot is discretized or not.
Notice that we can compute the QQ-plot, store it in `o` and then plot it (via `print.qqGam`).
```R
o <- qq.gam(lr.fit, rep = 10, method = "simul1", CI = "normal", show.reps = TRUE, 
            a.replin = list(alpha = 0.1), discrete = TRUE)
o 
```

The coarseness of the discretization grid is determined by the `ngr` argument:
```R
o <- qq.gam(lr.fit, rep = 10, method = "simul1", CI = "normal", show.reps = TRUE,
            ngr = 1e2, a.replin = list(alpha = 0.1), a.qqpoi = list(shape = 19))
o 
```

##### 2.1.2 The `check.gam` method

The `check.gam` method is similar to `mgcv::gam.check`, with the difference that it
produces a sequence of `ggplot` objects and that it sub-samples the residuals to 
avoid over-plotting (or stalling entirely) when dealing with large data sets.
Here is an example:
```R
set.seed(0)
dat <- gamSim(1, n = 200)
b <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat)

check(b,
      a.qq = list(method = "tnorm", 
                  a.cipoly = list(fill = "light blue")), 
      a.respoi = list(size = 0.5), 
      a.hist = list(bins = 10))
```

The `a.qq` argument is a list that gets passed directly to `mgcViz::qq.gam`. Similarly,
`a.repoi` is passed to `ggplot2::geom_points` and `a.hist` to `ggplot2::geom_hist`.

#### 2.2 New layered model checks

The `qq.gam` and `check.gam` functions are not layered, and in fact require using lists of arguments
to be passed to the underlying `ggplot2` layers. Instead, the methods described in this
section are fully layered, hence easy to extend and customize.

##### 2.2.1 One dimensional checks using `check1D`

This function allows to verify how the residuals vary along one covariate. Consider the 
following model:
```R
set.seed(4124)
n <- 1e4
x <- rnorm(n); y <- rnorm(n);

ob <- (x)^2 + (y)^2 + (0.2*abs(x) + 1)  * rnorm(n)
b <- bam(ob ~ s(x,k=30) + s(y, k=30), discrete = TRUE)
```

Here the responses variance varies a lot along $x$. Assume that we didn't know this, but
that we wanted to find out whether the residuals are heteroscedastic. We can start by doing
the following:
```R
ck <- check1D(b, "x")
ck
```

This produces a view along $x$, but as you can see that plot is initially empty. We might
want to add a layer showing the conditional distribution of the residuals along $x$ and another
containing a rug:
```R
ck + l_dens(type = "cond", alpha = 0.8) + l_rug(alpha = 0.2)
```

This suggests that the variance of the residuals might be lower in the middle ($x=0$), but it
is not entirely clear. The `l_densCheck` layer gives a more clear answer in this case:
```R
ck + l_densCheck()
```
This layers adds an heatmap proportional to $\{p(r|x)^{1/2} - p_m(r|x)^{1/2}\}^{1/3}$, where $r$ are the residuals, while $p$ and $p_m$ are their empirical and theoretical (model based) density. In particular, $p$ is estimated using the the fast k.d.e. method of Wand (1994) (implemented by the `kernSmooth` package) and $p_m$ is a standard normal density here. This plot makes clear that the residuals are over-dispersed when $x$ is far from zero.

The `l_gridCheck1D` provides another way of finding residuals patterns. For instance:
```R
b <- getViz(b, nsim = 50)
check1D(b, "x") + l_gridCheck1D(gridFun = sd, show.reps = TRUE)
```

Before calling `check1D` we convert `b` using `getViz`. This is because `l_gridCheck1D` need some
simulations to compute the confidence intervals. The simulations are done by `getViz` and then stored
inside `b`. `l_gridCheck1D` simply bins the residuals according to their $x$ values, and evaluates a user-defined function (`sd` here) over the observed and simulated residuals.

##### 2.2.2 Two dimensional checks using `check2D`

`check2D` is quite similar to `check1D`, but looks at the residuals along two covariates. Here is an
example where the mean effect follows the Rosenbrock function:
```R
set.seed(566)
n <- 1e4
X <- data.frame("x1"=rnorm(n, 0.5, 0.5), "x2"=rnorm(n, 1.5, 1))
X$y <- (1-X$x1)^2 + 100*(X$x2 - X$x1^2)^2 + rnorm(n, 0, 2)
b <- bam(y ~ te(x1, x2, k = 5), data = X, discrete = TRUE)
b <- getViz(b, nsim = 50)
```

We start by generating a 2D view:
```R
ck <- check2D(b, x1 = "x1", x2 = "x2")
```

Then we add the `l_gridCheck2D` layer:
```R
ck + l_gridCheck2D(gridFun = mean)
```

`l_gridCheck2D` bins the observed and simulated residuals, summarizes them using a scalar-valued
function (`mean` here), and adds an heatmap proportional to the observed summary in each cell, normalized
using the `nsim` summaries obtained using the simulations. Here the pattern in the residual means is not very well visible, due to outliers on the far right. The pattern is made more visible by zooming on the center of the distribution and by changing the size of the bins:
```R
ck + l_gridCheck2D(bw = c(0.05, 0.1)) + xlim(-1, 1) + ylim(0, 3)
```

As for smooth effect plots, we can list the available layers by doing:
```R
listLayers( ck ) 
```

The most sophisticated layer is probably `l_glyphs2D` which we illustrate here using an heteroscedastic model:
```R
set.seed(4124)
n <- 1e4
dat <- data.frame("x1" = rnorm(n), "x2" = rnorm(n))
dat$y <- (dat$x1)^2 + (dat$x2)^2 + (1*abs(dat$x1) + 1)  * rnorm(n)
b <- bam(y ~ s(x1,k=30) + s(x2, k=30), data = dat, discrete = TRUE)

ck <- check2D(b, x1 = "x1", x2 = "x2", type = "tnormal")
```

Similarly to `l_gridCheck2D`, `l_glyphs2D` bins the residuals according to two covariates, but the user-defined function used to summarize the residuals in each bin has to return a `data.frame` rather than a scalar. Here is 
an example:
```R
glyFun <- function(.d){
  .r <- .d$z
  .qq <- as.data.frame( density(.r)[c("x", "y")], n = 100 )
  .qq$colour <- rep(ifelse(length(.r)>50, "black", "red"), nrow(.qq))
  return( .qq )
}

ck + l_glyphs2D(glyFun = glyFun, ggLay = "geom_path", n = c(8, 8),
                 mapping = aes(x=gx, y=gy, group = gid, colour = I(colour)), 
                 height=1.5, width = 1)
```

Each glyph represend a kernel density of the residuals, with colours indicating whether we have more (black) or less (red) that 50 observations in that bin. It is clear that the residuals are much less variable for $x \approx 0$ than elsewhere. We can do the same using binned worm-plots: 
```R
glyFun <- function(.d){
  n <- nrow(.d)
  px <- qnorm( (1:n - 0.5)/(n) )
  py <- sort( .d$z )
  clr <- if(n > 50) { "black" } else { "red" }
  clr <- rep(clr, n)
  return( data.frame("x" = px, "y" = py - px, "colour" = clr))
}

ck + l_glyphs2D(glyFun = glyFun, ggLay = "geom_point", n = c(10, 10),
                mapping = aes(x=gx, y=gy, group = gid, colour = I(colour)),
                height=2, width = 1, size = 0.2) 
```

Notice that worm-plots (Buuren and Fredriks, 2001) are simply rotated QQ-plots. An horizontal plot indicates well specified residual model. An increasing (decreasing) worm indicates over (under) dispersion.



References
==========

-   Buuren, S. v. and Fredriks, M. (2001) Worm plot: a simple diagnostic device for modelling
growth reference curves, Statistics in medicine, 20, 1259–1277.

-   Murdoch, D. (2001) Rgl: An r interface to opengl, in Proceedings of DSC, p. 2.

-   Wand, M. P. (1994) Fast computation of multivariate kernel estimators, Journal of Computational and      Graphical Statistics, 3, 433–445

-   Wickham, H. (2009) ggplot2: Elegant Graphics for Data Analysis, Springer-Verlag New York.

-   Wickham, H. (2010) A layered grammar of graphics, Journal of
    Computational and Graphical Statistics, 19, 3–28.
    
-   Wood, S.N. (2017) Generalized Additive Models: An Introduction with R (2nd edition). 
    Chapman and Hall/CRC.

