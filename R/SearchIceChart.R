#' Search for available Ice Chart files
#'
#' Searches for weekly ice charts from the CIS, NIC, or DMI for a specific
#' region and year, and returns the results as a data.frame.
#'
#' @param institution Character. The ice service to query. One of:
#'   \itemize{
#'     \item \code{"CIS"} – Canadian Ice Service. Regions: \code{"East_Coast"},
#'       \code{"Eastern_Arctic"}, \code{"Great_Lakes"}, \code{"Hudson_Bay"},
#'       \code{"Western_Arctic"}.
#'       Years: 2006 to present.
#'     \item \code{"NIC"} – U.S. National Ice Center. Regions: \code{"north"},
#'       \code{"south"} (Antarctic production suspended since June 2023).
#'       Years: 2003 to present.
#'     \item \code{"DMI"} – Danish Meteorological Institute. Regions:
#'       \code{"Greenland_W"}, \code{"Qaanaaq"}, \code{"NorthWest"},
#'       \code{"CentralWest"},\code{"SouthWest"}, \code{"CapeFarewell"},
#'       \code{"SouthEast"}, \code{"CentralEast"}, \code{"NorthAndCentralEast"},
#'       \code{"NorthEast"},\code{"North"}.
#'       Years: 2004 to present.
#'   }
#'
#' @param region Character. The geographic region. See \code{institution}
#'   for valid options per institution.
#' @param year  Character or numeric. The year to search. See \code{institution}
#'   for valid ranges per institution.
#'
#' @return A \code{data.frame} with columns \code{filename}, \code{url},
#'   \code{date}, and \code{version} (where applicable).
#'
#' @examples
#' \dontrun{
#' # Canadian Ice Service
#' search_icechart(institution = "CIS", region = "Eastern_Arctic", year = 2020)
#'
#' # U.S. National Ice Center
#' search_icechart(institution = "NIC", region = "north", year = 2020)
#'
#' # Danish Meteorological Institute
#' search_icechart(institution = "DMI", region = "SouthEast", year = 2020)
#' }
#'
#' @export
search_icechart <- function(institution = "CIS", region, year) {

  institution <- base::toupper(institution)

  valid_institutions <- base::c("CIS", "NIC", "DMI")
  if (!institution %in% valid_institutions) {
    base::stop(
      "Invalid `institution`: '", institution, "'.\n",
      "Valid institutions are: ", base::paste(valid_institutions, collapse = ", "),
      call. = FALSE
    )
  }

  if (institution == "CIS") {
    .search_cis(region = region, year = year)
  } else if (institution == "NIC") {
    .search_nic(region = region, year = year)
  } else if (institution == "DMI") {
    .search_dmi(region = region, year = year)
  }
}


#--- Internal helper: CIS ------------------------------------------------------
.search_cis <- function(region, year) {
  valid_regions <- base::c("East_Coast", "Eastern_Arctic", "Great_Lakes",
                           "Hudson_Bay", "Western_Arctic")
  if (!region %in% valid_regions) {
    base::stop("Invalid `region` for CIS: '", region, "'.\n",
               "Valid regions: ", base::paste(valid_regions, collapse = ", "),
               call. = FALSE)
  }
  if (as.numeric(year) < 2006) {
    base::stop("CIS data available from 2006 onwards.", call. = FALSE)
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
  base::data.frame(
    filename = links,
    url = base::paste0(url, links),
    date = base::as.Date(datum_str, "%Y%m%d"),
    version = base::ifelse(base::grepl("_pl_b\\.tar$", links), "b", "a"),
    stringsAsFactors = FALSE
  )
}


#--- Internal helper: NIC ------------------------------------------------------
.search_nic <- function(region, year) {
  valid_regions <- base::c("north", "south")
  if (!region %in% valid_regions) {
    base::stop("Invalid `region` for NIC: '", region, "'.\n",
               "Valid regions: ", base::paste(valid_regions, collapse = ", "),
               call. = FALSE)
  }
  if (as.numeric(year) < 2003) {
    base::stop("NIC data available from 2003 onwards.", call. = FALSE)
  }
  url <- base::paste0("https://noaadata.apps.nsidc.org/NOAA/G10013/",
                      region, "/", year, "/")
  r <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0"))
  if (httr::http_error(r)) {
    base::stop("Directory not accessible: ", url,
               " (Status: ", httr::status_code(r), ")")
  }
  links <- rvest::read_html(httr::content(r, "text")) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href") |>
    base::grep("\\.zip$", x = _, value = TRUE)
  if (base::length(links) == 0) return(base::data.frame())
  datum_str <- base::regmatches(links, base::regexpr("\\d{8}", links))
  base::data.frame(
    filename = links,
    url= base::paste0(url, links),
    date = base::as.Date(datum_str, "%Y%m%d"),
    stringsAsFactors = FALSE
  )
}


#--- Internal helper: DMI ------------------------------------------------------
.search_dmi <- function(region, year) {

  year_num <- base::as.numeric(year)

  # Regionen for years
  if (year_num >= 2021) {
    valid_regions <- base::c("Qaanaaq", "NorthWest", "CentralWest", "SouthWest",
                             "CapeFarewell", "SouthEast", "CentralEast",
                             "NorthEast", "North")
  } else {
    valid_regions <- base::c("Qaanaaq", "NorthWest", "CentralWest", "SouthWest",
                             "CapeFarewell", "SouthEast", "CentralEast",
                             "NorthAndCentralEast", "NorthEast", "North")
  }

  if (!region %in% valid_regions) {
    base::stop(
      "Invalid `region` for DMI in ", year, ": '", region, "'.\n",
      "Valid regions: ", base::paste(valid_regions, collapse = ", "),
      call. = FALSE
    )
  }

  if (year_num < 2012) {
    base::stop("DMI SIGRID3 data available from 2012 onwards.", call. = FALSE)
  }

  # Access year folders
  base_url <- base::paste0("https://download.dmi.dk/public/ICESERVICE/SIGRID3/",
                           year, "/")
  r <- httr::GET(base_url, httr::add_headers(`User-Agent` = "Mozilla/5.0"))
  if (httr::http_error(r)) {
    base::stop("Directory not accessible: ", base_url,
               " (Status: ", httr::status_code(r), ")", call. = FALSE)
  }

  # View all subfolders for the year and filter by region
  all_folders <- rvest::read_html(httr::content(r, "text")) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href") |>
    base::grep(base::paste0("_", region, "_RIC/$"), x = _, value = TRUE)

  if (base::length(all_folders) == 0) {
    base::message("No charts found for region '", region, "' in ", year, ".")
    return(base::data.frame())
  }

  # Extract the date from folder names (YYYYMMDD)
  datum_str <- base::substr(all_folders, 1, 8)

  base::data.frame(
    folder = all_folders,
    url = base::paste0(base_url, all_folders),
    date = base::as.Date(datum_str, "%Y%m%d"),
    region = region,
    stringsAsFactors = FALSE
  )
}
