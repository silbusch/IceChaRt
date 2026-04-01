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
#' @param output_dir Directory to cache (default: NULL --> using working directory)
#' @param id_prefix Prefix for ice-polygon IDs (default: "poly")
#' @return sf-object with ice chart polygons and unique IDs
#' @export
downloadCISIceChart <- function(target_date = "2020-11-02",
                               region     = "Eastern_Arctic",
                               output_dir  = NULL,
                               id_prefix  = "poly") {

  target_date <- as.Date(target_date)
  year      <- format(target_date, "%Y")
  files     <- searchCISfiles(region, year)

  match <- files[files$datum == target_date & files$standard, ]

  if (nrow(match) == 0) {
    stop("No Chart for ", target_date, " in region '", region, "' found.\n",
         "Please select one of the alternative date: ", paste(files$datum[files$standard], collapse = ", "))
  }
  # create Folder for CIS Ice charts
  if (is.null(output_dir)) {
    main_dir  <- file.path(getwd(), "IceChaRt_output")
    output_dir <- file.path(main_dir, "IceChart")

    if (!dir.exists(main_dir)) {
      dir.create(main_dir, recursive = TRUE)
      message("Created output directory: ", main_dir)
    }

    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
      message("Created subdirectory: ", output_dir)
    }
  } else {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
      message("Created cache directory: ", output_dir)
    }
  }

  row    <- match[nrow(match), ]
  destfile <- file.path(output_dir, row$filename)

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

    # unpack in folder IceChart
  outdir <- file.path(output_dir, "ice_data", format(target_date, "%Y-%m-%d"))
  if (!dir.exists(outdir)) {
    dir.create(outdir, recursive = TRUE)
  }

  utils::untar(destfile, exdir = outdir)

  shp_files <- list.files(
    outdir,
    pattern = "\\.shp$",
    full.names = TRUE,
    recursive = TRUE
  )

  if (length(shp_files) == 0) {
    stop("No shapefile found in the archive: ", destfile)
  }

  shp <- shp_files[1]

  ice <- sf::st_read(shp, quiet = TRUE)

  # Create unique IDs
  ice$id <- paste0(
    id_prefix, "_",
    format(target_date, "%Y%m%d"), "_",
    seq_len(nrow(ice))
  )

  # ID as first column
  ice <- ice[, c("id", setdiff(names(ice), c("id", "geometry")), "geometry")]

  final_gpkg <- file.path(
    output_dir,
    paste0(tools::file_path_sans_ext(basename(shp)), "_with_id.gpkg")
  )

  sf::st_write(ice, final_gpkg, delete_dsn = TRUE, quiet = TRUE)

  message("CIS Ice Chart with written to: ", final_gpkg)

  # Metadata as attribute
  attr(ice, "region")    <- region
  attr(ice, "datum")     <- target_date
  attr(ice, "filename") <- row$filename

  ice
}
