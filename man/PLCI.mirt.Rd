\name{PLCI.mirt}
\alias{PLCI.mirt}
\title{Compute profiled-likelihood confidence intervals}
\usage{
  PLCI.mirt(mod, alpha = 0.05, parnum = NULL)
}
\arguments{
  \item{mod}{a converged mirt model}

  \item{alpha}{two-tailed alpha critical level}

  \item{parnum}{a numeric vector indicating which
  parameters to estimate. Use \code{\link{mod2values}} to
  determine parameter numbers. If \code{NULL}, all possible
  parameters are used}
}
\description{
  Computes profiled-likelihood based confidence intervals.
  Supports the inclusion of prior parameter distributions
  as well as equality constraints. For multidimensional
  models, the CI's for the slopes are not estimated due to
  the possibility of signs flipping during estimation. In
  unidimenisonal models, the slope parameters are assumed
  to be greater than zero, and a lower bound is imposed to
  ensure that sign flipping does not occur.
}
\examples{
\dontrun{
mirtCluster() #use all available cores to estimate CI's in parallel
dat <- expand.table(LSAT7)
mod <- mirt(dat, 1)

result <- PLCI.mirt(mod)
result

mod2 <- mirt(Science, 1)
result2 <- PLCI.mirt(mod2)
result2

#only estimate CI's slopes
sv <- mod2values(mod2)
parnum <- sv$parnum[sv$name == 'a1']
result3 <- PLCI.mirt(mod2, parnum=parnum)
result3

}
}
\seealso{
  \code{\link{boot.mirt}}
}
\keyword{likelihood}
\keyword{profiled}

