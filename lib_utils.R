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


