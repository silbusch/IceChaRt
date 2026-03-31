#' List of available Ice Chart files
#'
#' @param region "East_Coast", “Eastern_Arctic”, "Great_Lakes", “Hudson_Bay”, "Western_Arctic")
#' @param year Choose between "2006" to current year
#' @return data.frame with dataname, URLs, date and version
#' @export
searchCISfiles <- function(region = "Eastern_Arctic", year = "2024") {
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


#' Download the Ice Chart and load it as an SF object
#'
#' @param target_date Date as string in format "YYYY-MM-DD" or as date object
#' @param region Region (default: "Eastern_Arctic")
#' @param cache_dir Directory to cache (default: tempdir())
#' @param id_prefix Prefix for ice-polygon IDs (default: "poly")
#' @return sf-object with ice chart polygons and unique IDs
#' @export
downloadCISIceChart <- function(target_date = "2020-11-02",
                               region     = "Eastern_Arctic",
                               cache_dir  = tempdir(),
                               id_prefix  = "poly") {

  target_date <- as.Date(target_date)
  year      <- format(target_date, "%Y")
  files     <- searchCISfiles(region, year)

  match <- files[files$datum == target_date & files$standard, ]

  if (nrow(match) == 0) {
    stop("No Chart for ", target_date, " in region '", region, "' found.\n",
         "Please select one of the alternative date: ", paste(files$datum[files$standard], collapse = ", "))
  }

  row    <- match[nrow(match), ]
  destfile <- file.path(cache_dir, row$filename)

  # Cache: download only, if data is not already there
  if (!file.exists(destfile)) {
    message("Download: ", row$filename)
    httr::GET(row$url,
              httr::add_headers(`User-Agent` = "Mozilla/5.0"),
              httr::write_disk(destfile, overwrite = TRUE),
              httr::progress())
  } else {
    message("From cache: ", destfile)
  }

  outdir <- file.path(cache_dir, "ice_data", format(target_date))
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  utils::untar(destfile, exdir = outdir)

  shp <- list.files(outdir, pattern = "\\.shp$",
                    full.names = TRUE, recursive = TRUE)[1]

  if (is.na(shp)) stop("No shapefile found in the archive: ", destfile)

  ice <- sf::st_read(shp, quiet = TRUE)

  # Create unique IDs
  ice$id <- paste0(
    id_prefix, "_",
    format(target_date, "%Y%m%d"), "_",
    seq_len(nrow(ice))
  )

  # ID as first column
  ice <- ice[, c("id", setdiff(names(ice), c("id", "geometry")), "geometry")]

  # Metadata as attribute
  attr(ice, "region")    <- region
  attr(ice, "datum")     <- target_date
  attr(ice, "filename") <- row$filename

  ice
}
