#' Download Ice Chart files
#'
#' Downloads ice chart files from the CIS, NIC, or DMI for a specific region
#' and time period. Files are automatically converted to GeoPackage (.gpkg)
#' format and saved to \code{IceChaRt_output/ice_charts/} in the current
#' working directory. Original files are deleted after conversion.
#'
#' @param institution Character. The ice service to download from. One of:
#'   \itemize{
#'     \item \code{"CIS"} – Canadian Ice Service. Regions: \code{"East_Coast"},
#'       \code{"Eastern_Arctic"}, \code{"Great_Lakes"}, \code{"Hudson_Bay"},
#'       \code{"Western_Arctic"}. Years: 2006 to present.
#'     \item \code{"NIC"} – U.S. National Ice Center. Regions: \code{"north"},
#'       \code{"south"} (Antarctic suspended since June 2023).
#'       Years: 2003 to present.
#'     \item \code{"DMI"} – Danish Meteorological Institute. Regions (2021+):
#'       \code{"Qaanaaq"}, \code{"NorthWest"}, \code{"CentralWest"},
#'       \code{"SouthWest"}, \code{"CapeFarewell"}, \code{"SouthEast"},
#'       \code{"CentralEast"}, \code{"NorthEast"}, \code{"North"}.
#'       Regions (before 2021): same plus \code{"NorthAndCentralEast"}.
#'       Years: 2012 to present.
#'   }
#' @param region Character. The geographic region. See \code{institution}
#'   for valid options.
#' @param year Numeric or character. The year to download. Required if
#'   \code{date}, \code{date_from}, and \code{date_to} are all \code{NULL}.
#' @param date Character. An exact date in \code{"YYYY-MM-DD"} format.
#'   Cannot be combined with \code{date_from}/\code{date_to}.
#' @param date_from Character. Start of date range in \code{"YYYY-MM-DD"}
#'   format. Must be combined with \code{date_to}.
#' @param date_to Character. End of date range in \code{"YYYY-MM-DD"} format.
#'   Must be combined with \code{date_from}.
#' @param dest Character. Base directory for output. Defaults to current
#'   working directory. Files are saved to \code{dest/IceChaRt_output/ice_charts/}.
#'
#' @return Invisibly returns a \code{data.frame} with columns \code{id},
#'   \code{filename}, and \code{path} of all downloaded \code{.gpkg} files.
#'
#' @examples
#' \dontrun{
#' # Exact date
#' download_icechart(institution = "DMI",
#'                   region = "CapeFarewell",
#'                   date = "2024-12-31")
#'
#' # Date range
#' download_icechart(institution = "CIS",
#'                   region = "Eastern_Arctic",
#'                   date_from = "2020-06-01",
#'                   date_to = "2020-08-31")
#'
#' # Full year
#' download_icechart(institution = "NIC",
#'                   region = "north",
#'                   year = 2020)
#' }
#'
#' @export
download_icechart <- function(institution,
                              region,
                              year = NULL,
                              date = NULL,
                              date_from = NULL,
                              date_to = NULL,
                              dest = base::getwd()) {

  institution <- base::toupper(institution)

  #--- Validate institution ----------------------------------------------------
  valid_institutions <- base::c("CIS", "NIC", "DMI")
  if (!institution %in% valid_institutions) {
    base::stop(
      "Invalid `institution`: '", institution, "'.\n",
      "Valid institutions are: ", base::paste(valid_institutions, collapse = ", "),
      call. = FALSE
    )
  }

  #--- Validate date -----------------------------------------------------------
  if (!base::is.null(date) && (!base::is.null(date_from) || !base::is.null(date_to))) {
    base::stop("`date` cannot be combined with `date_from`/`date_to`.", call. = FALSE)
  }
  if (!base::is.null(date_from) && base::is.null(date_to) ||
      base::is.null(date_from) && !base::is.null(date_to)) {
    base::stop("`date_from` and `date_to` must both be provided.", call. = FALSE)
  }
  if (base::is.null(date) && base::is.null(date_from) && base::is.null(year)) {
    base::stop("Please provide either `date`, `date_from`/`date_to`, or `year`.",
               call. = FALSE)
  }

  #--- Get the year from date --------------------------------------------------
  if (!base::is.null(date)) {
    year_use <- base::format(base::as.Date(date), "%Y")
  } else if (!base::is.null(date_from)) {
    year_use <- base::format(base::as.Date(date_from), "%Y")
  } else {
    year_use <- base::as.character(year)
  }

  #--- Start searching ---------------------------------------------------------
  # calling the search_icechart() function with URLs
  search_results <- search_icechart(institution = institution,
                                    region= region,
                                    year = year_use)

  if (base::nrow(search_results) == 0) {
    base::message("No charts found for the given parameters.")
    return(base::invisible(NULL))
  }

  #--- Filter the date ----------------------------------------------------------
  if (!base::is.null(date)) {
    target <- base::as.Date(date)
    search_results <- search_results[search_results$date == target, ]
  } else if (!base::is.null(date_from)) {
    d_from <- base::as.Date(date_from)
    d_to <- base::as.Date(date_to)
    search_results <- search_results[
      search_results$date >= d_from & search_results$date <= d_to, ]
  }

  if (base::nrow(search_results) == 0) {
    base::message("No charts found for the specified date(s).")
    return(base::invisible(NULL))
  }

  #--- Create subfolder for saving --------------------------------------------
  out_dir <- base::file.path(dest, "IceChaRt_output", "ice_charts")
  base::dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  #---Temporary folder for extracting files ------------------------------------
  tmp_dir <- base::tempfile(pattern = "IceChaRt_tmp_")
  base::dir.create(tmp_dir, recursive = TRUE)
  on.exit(base::unlink(tmp_dir, recursive = TRUE), add = TRUE)

  #--- Downloads by institution ------------------------------------------------
  if (institution == "CIS") {
    result <- .download_cis(search_results = search_results,
                            out_dir = out_dir,
                            tmp_dir = tmp_dir,
                            prefix = "CIS")
  } else if (institution == "NIC") {
    result <- .download_nic(search_results = search_results,
                            out_dir = out_dir,
                            tmp_dir = tmp_dir,
                            prefix = "NIC")
  } else if (institution == "DMI") {
    result <- .download_dmi(search_results = search_results,
                            out_dir = out_dir,
                            tmp_dir = tmp_dir,
                            prefix = "DMI")
  }
  base::message("Files saved to: ", out_dir)
  base::invisible(result)
}

#--- Transform Shapefile to .gpkg ----------------------------------------------
.shp_to_gpkg <- function(shp_path, gpkg_path) {
  v <- terra::vect(shp_path)
  # create new columns with unique IDs
  v$ID_NEW <- base::seq_len(terra::nrow(v))
  terra::writeVector(v, gpkg_path, filetype = "GPKG", overwrite = TRUE)
}

#--- CIS download --------------------------------------------------------------
.download_cis <- function(search_results, out_dir, tmp_dir, prefix) {
  downloaded <- base::list()

  for (i in base::seq_len(base::nrow(search_results))) {
    url <- search_results$url[i]
    orig_filename <- search_results$filename[i]
    tar_path <- base::file.path(tmp_dir, orig_filename)

    base::message("Downloading (", i, "/", base::nrow(search_results), "): ",
                  orig_filename)

    # Download .tar
    r <- httr::GET(url,
                   httr::add_headers(`User-Agent` = "Mozilla/5.0"),
                   httr::write_disk(tar_path, overwrite = TRUE),
                   httr::progress())

    if (httr::http_error(r)) {
      base::warning("Failed to download: ", url, call. = FALSE)
      next
    }

    # Extract
    extract_dir <- base::file.path(tmp_dir, base::sub("\\.tar$", "", orig_filename))
    base::dir.create(extract_dir, showWarnings = FALSE)
    utils::untar(tar_path, exdir = extract_dir)

    # finding .shp and convert to .gpkg
    shp_files <- base::list.files(extract_dir, pattern = "\\.shp$",
                                  full.names = TRUE, recursive = TRUE)

    for (shp in shp_files) {
      shp_base <- tools::file_path_sans_ext(base::basename(shp))
      gpkg_name <- base::paste0(prefix, "_", shp_base, ".gpkg")
      gpkg_path <- base::file.path(out_dir, gpkg_name)

      base::message("  Converting to .gpkg: ", gpkg_name)
      .shp_to_gpkg(shp, gpkg_path)

      downloaded[[base::length(downloaded) + 1]] <- base::list(
        filename = gpkg_name,
        path     = gpkg_path
      )
    }
  }

  base::data.frame(
    id= base::seq_len(base::length(downloaded)),
    filename = base::sapply(downloaded, `[[`, "filename"),
    path = base::sapply(downloaded, `[[`, "path"),
    stringsAsFactors = FALSE
  )
}

#--- NIC download --------------------------------------------------------------
.download_nic <- function(search_results, out_dir, tmp_dir, prefix) {
  downloaded <- base::list()

  for (i in base::seq_len(base::nrow(search_results))) {
    url <- search_results$url[i]
    orig_filename <- search_results$filename[i]
    zip_path <- base::file.path(tmp_dir, orig_filename)

    base::message("Downloading (", i, "/", base::nrow(search_results), "): ",
                  orig_filename)

    # Download .zip
    r <- httr::GET(url,
                   httr::add_headers(`User-Agent` = "Mozilla/5.0"),
                   httr::write_disk(zip_path, overwrite = TRUE),
                   httr::progress())

    if (httr::http_error(r)) {
      base::warning("Failed to download: ", url, call. = FALSE)
      next
    }

    extract_dir <- base::file.path(tmp_dir, base::sub("\\.zip$", "", orig_filename))
    base::dir.create(extract_dir, showWarnings = FALSE)
    utils::unzip(zip_path, exdir = extract_dir)

    shp_files <- base::list.files(extract_dir, pattern = "\\.shp$",
                                  full.names = TRUE, recursive = TRUE)

    for (shp in shp_files) {
      shp_base <- tools::file_path_sans_ext(base::basename(shp))
      gpkg_name <- base::paste0(prefix, "_", shp_base, ".gpkg")
      gpkg_path <- base::file.path(out_dir, gpkg_name)

      base::message("  Converting to .gpkg: ", gpkg_name)
      .shp_to_gpkg(shp, gpkg_path)

      downloaded[[base::length(downloaded) + 1]] <- base::list(
        filename = gpkg_name,
        path     = gpkg_path
      )
    }
  }

  base::data.frame(
    id = base::seq_len(base::length(downloaded)),
    filename = base::sapply(downloaded, `[[`, "filename"),
    path = base::sapply(downloaded, `[[`, "path"),
    stringsAsFactors = FALSE
  )
}


#---  DMI download -------------------------------------------------------------
.download_dmi <- function(search_results, out_dir, tmp_dir, prefix) {
  extensions <- base::c(".shp", ".shx", ".dbf", ".prj", ".cpg")
  downloaded <- base::list()

  for (i in base::seq_len(base::nrow(search_results))) {
    folder_url <- search_results$url[i]
    folder <- search_results$folder[i]
    basename <- base::sub("/$", "", folder)

    base::message("Downloading (", i, "/", base::nrow(search_results), "): ",
                  basename)

    # Download all shapefile components
    for (ext in extensions) {
      orig_filename <- base::paste0(basename, ext)
      url <- base::paste0(folder_url, orig_filename)
      out_path <- base::file.path(tmp_dir, orig_filename)

      r <- httr::GET(url,
                     httr::add_headers(`User-Agent` = "Mozilla/5.0"),
                     httr::write_disk(out_path, overwrite = TRUE))

      if (httr::http_error(r)) {
        base::warning("Failed to download: ", url, call. = FALSE)
      }
    }

    # search .shp in tmp_dir and convert in .gpkg
    shp_path <- base::file.path(tmp_dir, base::paste0(basename, ".shp"))
    gpkg_name <- base::paste0(prefix, "_", basename, ".gpkg")
    gpkg_path <- base::file.path(out_dir, gpkg_name)

    if (base::file.exists(shp_path)) {
      base::message("  Converting to .gpkg: ", gpkg_name)
      .shp_to_gpkg(shp_path, gpkg_path)

      downloaded[[base::length(downloaded) + 1]] <- base::list(
        filename = gpkg_name,
        path     = gpkg_path
      )
    }
  }

  base::data.frame(
    id = base::seq_len(base::length(downloaded)),
    filename = base::sapply(downloaded, `[[`, "filename"),
    path = base::sapply(downloaded, `[[`, "path"),
    stringsAsFactors = FALSE
  )
}
