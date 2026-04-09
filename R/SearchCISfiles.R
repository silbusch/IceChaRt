#' List of available Ice Chart files of the Canadian Ice Service (CIS)
#'
#' This function searches for the weekly ice charts from the CIS
#' for a specific region and year, and prints the results to the users console.
#'
#' @param region "East_Coast", “Eastern_Arctic”, "Great_Lakes", “Hudson_Bay”, "Western_Arctic"
#' @param year Choose between "2006" to current year
#' @return data.frame with dataname, URLs, date and version
#'
#'@examples
#' \dontrun{
#'
#'search_cis_icechart(region="Eastern_Arctic", year="2020")
#' }
#'
#' @export
search_cis_icechart <- function(region = "Eastern_Arctic", year = "2020") {

  valid_regions <- base::c("East_Coast", "Eastern_Arctic", "Great_Lakes", "Hudson_Bay", "Western_Arctic")

  if (!region %in% valid_regions) {
    base::stop(
      "Invalid `region`: '", region, "'.\n",
      "Valid regions are: ", base::paste(valid_regions, collapse = ", "), "\n",
      call. = FALSE
    )
  }

  if (year < 2006) {
    base::stop(
      "Invalid `year`: '", year, "'.\n",
      "Valid years are between 2006 and today.",
      call. = FALSE
    )
  }

  url <- base::paste0("https://noaadata.apps.nsidc.org/NOAA/G02171/",
                      region, "/", year, "/")
  r <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0"))

  if (httr::http_error(r)) {
    base::stop("Directory not accessible: ", url,
               " (Status: ", httr::status_code(r), ")")
  }

  links <- rvest::read_html(httr::content(r, "text")) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href") |>
    base::grep("^cis_SGRD.*\\.tar$", x = _, value = TRUE)

  if (base::length(links) == 0) return(base::data.frame())

  datum_str <- base::regmatches(links, base::regexpr("\\d{8}", links))
  standard  <- base::grepl("_pl_(a|b)\\.tar$", links)

  base::data.frame(
    filename = links,
    url       = base::paste0(url, links),
    datum     = base::as.Date(datum_str, "%Y%m%d"),
    version   = base::ifelse(base::grepl("_pl_b\\.tar$", links), "b", "a"),
    standard  = standard,
    stringsAsFactors = FALSE
  )
}
