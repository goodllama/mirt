\name{wald}
\alias{print.wald}
\alias{wald}
\title{Wald test for mirt models}
\usage{
  wald(object, L, C = 0)

  \method{print}{wald} (x, ...)
}
\arguments{
  \item{L}{a coefficient matrix with dimensions nconstrasts
  x npars, or a vector if only one set of contrasts is
  being tested. Omitting this value will return the column
  names of the information matrix used to identify the
  (potentially constrained) parameters}

  \item{object}{estimated object from \code{mirt},
  \code{bfactor}, \code{multipleGroup}, or
  \code{mixedmirt}}

  \item{C}{a constant vector/matrix to be compared along
  side L}

  \item{x}{an object of class 'wald'}

  \item{...}{additional arguments to be passed}
}
\description{
  Compute a Wald test given an \code{L} vector or matrix of
  numeric contrasts. Requires that the model information
  matrix be computed (including \code{SE = TRUE} when using
  the EM method). Use \code{wald(model)} to observe how the
  information matrix columns are named, especially if the
  estimated model contains constrained parameters (e.g.,
  1PL). The information matrix names are labelled according
  to which parameter number(s) they correspond to (to check
  the numbering use \code{\link{mod2values}} on the
  estimated object).
}
\examples{
\dontrun{
#View parnumber index
data(LSAT7)
data <- expand.table(LSAT7)
mod <- mirt(data, 1, SE = TRUE)
coef(mod)

#see how the information matrix relates to estimated parameters, and how it lines up with the index
(infonames <- wald(mod))
index <- mod2values(mod)
index

#second item slope equal to 0?
L <- rep(0, 10)
names(L) <- infonames
L[3] <- 1
wald(mod, L)

#simultaneously test equal factor slopes for item 2 and 3, and 4 and 5
L <- matrix(0, 2, 10)
colnames(L) <- infonames #colnames() not required
L[1,1] <- L[2, 7] <- 1
L[1,3] <- L[2, 9] <- -1
L
wald(mod, L)

#logLiklihood tests (requires estimating a new model)
mod2 <- mirt(data, 1, constrain = list(c(1,5), c(13,17)))
anova(mod2, mod)
}
}
\keyword{wald}

