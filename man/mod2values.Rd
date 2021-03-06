\name{mod2values}
\alias{mod2values}
\title{Convert an estimated mirt model to special data.frame}
\usage{
  mod2values(x)
}
\arguments{
  \item{x}{an estimated model x from the mirt package}
}
\description{
  Given an estimated model from any of mirt's model fitting
  functions this function will convert the model parameters
  into the design data frame of starting values and other
  parameter characteristics (similar to using the
  \code{pars = 'values'} for obtaining starting values).
}
\examples{
\dontrun{
dat <- expand.table(LSAT7)
mod <- mirt(dat, 1)
values <- mod2values(mod)

#use the converted values as starting values in a new model
mod2 <- mirt(dat, 1, pars = values)

}
}
\author{
  Phil Chalmers \email{rphilip.chalmers@gmail.com}
}
\keyword{convert}
\keyword{model}

