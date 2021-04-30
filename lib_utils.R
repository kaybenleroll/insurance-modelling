verbosely <- function(.f, show_prob = 0.01) {
  function(x, ...) {
    if (runif(1) < show_prob) {
      message("Running function for ", x)
    }

    .f(x, ...)
  }
}


resolve_conflicts <- function(pkg_priority) {
  get_index <- function(pkg_name) {
    idx <- str_which(pkg_priority, pkg_name)

    if(length(idx) == 0) {
      idx <- 0L
    }

    return(idx)
  }

  conflict_lst <- conflict_scout()

  for(func_name in names(conflict_lst)) {
    pkg_index <- map_int(conflict_lst[[func_name]], get_index)

    pkg_index <- pkg_index[pkg_index > 0]

    if(length(pkg_index) == 0) {
      pkg_use <- conflict_lst[[func_name]][1]
    } else {
      pkg_use <- pkg_index %>%
        min() %>%
        pkg_priority[.]

    }

    conflict_prefer(func_name, pkg_use)
  }
}


convert_counts_string <- function(x, max_count) {
  x <- x %>% pmin(max_count) %>% as.character()

  cat_count <- if_else(x == max_count, str_c(x, "+"), x)

  return(cat_count)
}


calculate_freqmodel_output_data <- function(prior_mean, prior_sd,
                                            incpt_mean, incpt_sd,
                                            autoscale,
                                            fit_formula,
                                            fit_data_tbl,
                                            priorparam_input_tbl,
                                            inc_stanreg  = FALSE,
                                            dist_family  = "poisson",
                                            calc_priorpd = FALSE) {

  n_sample <- priorparam_input_tbl %>% nrow()

  freqmodel_stanreg <- stan_glm(
    fit_formula,
    family   = dist_family %>% get() %>% exec(),
    data     = fit_data_tbl,
    offset   = log(exposure),
    iter     = 500,
    chains   = 4,
    QR       = TRUE,
    prior_PD = calc_priorpd,
    seed     = stan_seed,
    prior_intercept = normal(location = incpt_mean, scale = incpt_sd, autoscale = autoscale),
    prior           = normal(location = prior_mean, scale = prior_sd, autoscale = autoscale)
  )

  freqmodel_freqmean_tbl <- freqmodel_stanreg %>%
    add_fitted_draws(
      newdata = priorparam_input_tbl,
      offset  = rep(1, n_sample),
      value   = "freq_mean"
      ) %>%
    ungroup() %>%
    select(policy_id, .draw, freq_mean)

  freqmodel_sampcount_tbl <- freqmodel_stanreg %>%
    add_predicted_draws(
      newdata    = priorparam_input_tbl,
      offset     = rep(1, n_sample),
      prediction = "sample_count"
      ) %>%
    ungroup() %>%
    select(policy_id, .draw, sample_count)

  freqmodel_data_tbl <- freqmodel_freqmean_tbl %>%
    inner_join(freqmodel_sampcount_tbl, by = c("policy_id", ".draw"))

  freqmodel_params_tbl <- freqmodel_stanreg %>%
    tidy_draws()

  freqmodel_lst <- list(
    freqmodel_params = freqmodel_params_tbl,
    freqmodel_output = freqmodel_data_tbl
  )

  if(inc_stanreg == TRUE) {
    freqmodel_lst$stanreg <- freqmodel_stanreg
  }

  return(freqmodel_lst)
}


calculate_mean_freq_summary <- function(data_tbl) {
  summary_tbl <- data_tbl %>%
    summarise(
      .groups = "drop",

      freqmean_min  = min(freq_mean) %>% round(4),
      freqmean_p10  = quantile(freq_mean, 0.10) %>% round(4),
      freqmean_p25  = quantile(freq_mean, 0.25) %>% round(4),
      freqmean_p50  = quantile(freq_mean, 0.50) %>% round(4),
      freqmean_p75  = quantile(freq_mean, 0.75) %>% round(4),
      freqmean_p90  = quantile(freq_mean, 0.90) %>% round(4),
      freqmean_max  = max(freq_mean) %>% round(4),

      freqmean_mean = mean(freq_mean) %>% round(4),
      freqmean_sd   = sd(freq_mean) %>% round(4)
    )

  return(summary_tbl)
}


#construct_
