\name{boot.mirt}
\alias{boot.mirt}
\title{Calculate bootstrapped standard errors for estimated models}
\usage{
  boot.mirt(x, R = 100, return.boot = TRUE, ...)
}
\arguments{
  \item{x}{an estimated object from \code{mirt},
  \code{bfactor}, or \code{multipleGroup}}

  \item{R}{number of draws to use (passed to the
  \code{boot()} function)}

  \item{return.boot}{logical; return the estimated object
  from the \code{boot} package? If \code{FALSE} the
  estimated model is returned with the bootstrapped
  standard errors}

  \item{...}{additional arguments to be passed on to
  \code{boot(...)}}
}
\description{
  Given an internal mirt object estimate the bootstrapped
  standard errors. It may be beneficial to run the
  computations using multicore architecture (e.g., the
  \code{parallel} package).
}
\examples{
\dontrun{
mod <- mirt(Science, 1)
booted <- boot.mirt(mod)
booted

#run in parallel using snow backend
modwithboot <- boot.mirt(mod, return.boot = FALSE, parallel = 'snow', ncpus = 4L)
coef(modwithboot)

}
}
\seealso{
  \code{\link{PLCI.mirt}}
}
\keyword{bootstrapped}
\keyword{errors}
\keyword{standard}

