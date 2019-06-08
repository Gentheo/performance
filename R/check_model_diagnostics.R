.diag_vif <- function(model) {
  dat <- .compact_list(check_collinearity(model))
  if (is.null(dat)) return(NULL)
  dat$group <- "low"
  dat$group[dat$VIF >= 5 & dat$VIF < 10] <- "moderate"
  dat$group[dat$VIF >= 10] <- "high"

  if (ncol(dat) == 5) {
    colnames(dat) <- c("x", "y", "se", "facet", "group")
    dat[, c("x", "y", "facet", "group")]
  } else {
    colnames(dat) <- c("x", "y", "se", "group")
    dat[, c("x", "y", "group")]
  }
}


#' @importFrom stats residuals rstudent fitted
.diag_qq <- function(model) {
  if (inherits(model, c("lme", "lmerMod", "merMod", "glmmTMB"))) {
    res_ <- sort(stats::residuals(model), na.last = NA)
  } else {
    res_ <- sort(stats::rstudent(model), na.last = NA)
  }

  fitted_ <- sort(stats::fitted(model), na.last = NA)
  stats::na.omit(data.frame(x = fitted_, y = res_))
}



#' @importFrom stats qnorm ppoints
.diag_reqq <- function(model, level = .95, model_info) {
  # check if we have mixed model
  if (!model_info$is_mixed) return(NULL)

  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' required for this function to work. Please install it.", call. = FALSE)
  }

  if (inherits(model, "glmmTMB")) {
    var_attr <- "condVar"
    re   <- .collapse_cond(lme4::ranef(model, condVar = TRUE))
  } else {
    var_attr <- "postVar"
    re   <- lme4::ranef(model, condVar = TRUE)
  }

  se <- lapply(re, function(.x) {
    pv   <- attr(.x, var_attr, exact = TRUE)
    cols <- seq_len(dim(pv)[1])
    unlist(lapply(cols, function(.y) sqrt(pv[.y, .y, ])))
  })


  mapply(function(.re, .se) {
    ord  <- unlist(lapply(.re, order)) + rep((0:(ncol(.re) - 1)) * nrow(.re), each = nrow(.re))

    df.y <- unlist(.re)[ord]
    df.ci <- stats::qnorm((1 + level) / 2) * .se[ord]

    data.frame(
      x = rep(stats::qnorm(stats::ppoints(nrow(.re))), ncol(.re)),
      y = df.y,
      conf.low = df.y - df.ci,
      conf.high = df.y + df.ci,
      facet = gl(ncol(.re), nrow(.re), labels = names(.re)),
      stringsAsFactors = FALSE,
      row.names = NULL
    )}, re, se, SIMPLIFY = FALSE)
}




#' @importFrom bayestestR estimate_density
#' @importFrom stats residuals sd
.diag_norm <- function(model) {
  r <- stats::residuals(model)
  dat <- as.data.frame(bayestestR::estimate_density(r))
  dat$curve <- stats::dnorm(seq(min(dat$x), max(dat$x), length.out = nrow(dat)),  mean(r),  stats::sd(r))
  dat
}




#' @importFrom stats residuals fitted
.diag_ncv <- function(model) {
  data.frame(
    x = stats::fitted(model),
    y = stats::residuals(model)
  )
}


#' @importFrom insight get_variance_residual
#' @importFrom stats rstandard fitted
.diag_homogeneity <- function(model) {
  r <- tryCatch(
    {
      if (inherits(model, "merMod")) {
        stats::residuals(model, scaled = TRUE)
      } else if (inherits(model, c("glmmTMB", "MixMod"))) {
        sigma <- sqrt(insight::get_variance_residual(model))
        stats::residuals(model) / sigma
      } else {
        stats::rstandard(model)
      }
    },
    error = function(e) { NULL }
  )

  if (is.null(r)) return(NULL)

  data.frame(
    x = stats::fitted(model),
    y = sqrt(abs(r))
  )
}