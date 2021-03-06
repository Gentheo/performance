% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/performance_lrt.R
\name{performance_lrt}
\alias{performance_lrt}
\title{Likelihood-Ratio-Test for Model Comparison}
\usage{
performance_lrt(...)
}
\arguments{
\item{...}{Multiple model objects, which should respond to \code{anova()}.}
}
\value{
A data frame, based on the results from \code{anova()}.
}
\description{
Compute Likelihood-Ratio-Test for model comparison.
}
\details{
This only makes statistical sense if the models are nested. It is conventional to list the models from smallest to largest, but this is up to the user. The ouput shows the tests of the models against one another in the order specified.
}
\examples{
m1 <- lm(mpg ~ wt + cyl, data = mtcars)
m2 <- lm(mpg ~ wt + cyl + gear, data = mtcars)
m3 <- lm(mpg ~ wt + cyl + gear + disp, data = mtcars)
performance_lrt(m1, m2, m3)

}
\seealso{
\code{\link[=compare_performance]{compare_performance()}} to compare performance of many different models.
}
