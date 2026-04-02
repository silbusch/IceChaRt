# To-Do: Need to add an option for user to see, which region and year is possible

#' List of available Ice Chart files
#'
#' @param region "East_Coast", “Eastern_Arctic”, "Great_Lakes", “Hudson_Bay”, "Western_Arctic")
#' @param year Choose between "2006" to current year
#' @return data.frame with dataname, URLs, date and version
#' @export
searchCISfiles <- function(region = "Eastern_Arctic", year = "2024") {

  valid_regions <- c("East_Coast", "Eastern_Arctic", "Great_Lakes", "Hudson_Bay", "Western_Arctic")

  if (!region %in% valid_regions) {
    stop(
      "Invalid `region`: '", region, "'.\n",
      "Valid regions are: ", paste(valid_regions, collapse = ", "), "\n",
      call. = FALSE
    )
  }

  url <- paste0("https://noaadata.apps.nsidc.org/NOAA/G02171/",
                region, "/", year, "/")
  r <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0"))

  if (httr::http_error(r)) {
    stop("Directory not accessible: ", url,
         " (Status: ", httr::status_code(r), ")")
  }

  links <- rvest::read_html(httr::content(r, "text")) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href") |>
    grep("^cis_SGRD.*\\.tar$", x = _, value = TRUE)

  if (length(links) == 0) return(data.frame())

  datum_str <- regmatches(links, regexpr("\\d{8}", links))
  standard  <- grepl("_pl_(a|b)\\.tar$", links)

  data.frame(
    filename = links,
    url       = paste0(url, links),
    datum     = as.Date(datum_str, "%Y%m%d"),
    version   = ifelse(grepl("_pl_b\\.tar$", links), "b", "a"),
    standard  = standard,
    stringsAsFactors = FALSE
  )
}
