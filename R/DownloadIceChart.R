#' Download the Ice Chart and load it as an SF object and add unique IDs
#'
#'This function downloads a weekly ice chart from the Canadian Ice Service,
#'creates a new column containing IDs, and saves the SF object.
#'
#' @param target_date Date as string in format "YYYY-MM-DD" or as date object
#' @param region Region (default: "Eastern_Arctic"). Valid options: "East_Coast",
#'   "Eastern_Arctic", "Great_Lakes", "Hudson_Bay", "Western_Arctic".
#' @param out_dir Optional base directory for output. If `NULL`, the current
#'   working directory is used. Output is always saved to `IceChaRt_output/icechart_cis/`.
#'
#' @return An `sf` object with ice chart polygons and unique IDs. The attributes
#'   `region`, `datum`, and `filename` are attached to the returned object.
#'
#' @details
#' If `out_dir` is `NULL`, files are saved to `IceChaRt_output/icechart_cis/`
#' relative to the current working directory. If the chart for the requested date
#' has already been downloaded, it is loaded from cache. The chart is saved as a
#' GeoPackage (`.gpkg`) with a new unique ID column (`ID_NEW`) added as the first column.
#'
#' @export
downloadCISIceChart <- function(target_date = "2020-11-02",
                               region     = "Eastern_Arctic",
                               out_dir  = NULL) {

  valid_regions <- c("East_Coast", "Eastern_Arctic", "Great_Lakes", "Hudson_Bay", "Western_Arctic")

  if (!region %in% valid_regions) {
    stop(
      "Invalid `region`: '", region, "'.\n",
      "Valid regions are: ", paste(valid_regions, collapse = ", "), "\n",
      call. = FALSE
    )
  }


  target_date <- base::as.Date(target_date)
  year <- base::format(target_date, "%Y")
  files <- searchCISfiles(region, year)
  match <- files[files$datum == target_date & files$standard, ]
  match <- files[files$datum == target_date & files$standard, ]

  if (base::nrow(match) == 0) {
    stop("No Chart for ", target_date, " in region '", region, "' found.\n",
         "Please select one of the alternative date: ",
         base::paste(files$datum[files$standard], collapse = ", "),
    )
  }
  # Output directory handling
  if (base::is.null(out_dir)) {
    main_dir <- base::file.path(base::getwd(), "IceChaRt_output")
    output_dir <- base::file.path(main_dir, "icechart_cis")
  } else {
    main_dir <- base::file.path(out_dir, "IceChaRt_output")
    output_dir <- base::file.path(main_dir, "icechart_cis")
  }

  for (d in c(main_dir, output_dir)) {
    if (!base::dir.exists(d)) {
      base::dir.create(d, recursive = TRUE)
      base::message("Created directory: ", d)
    }
  }

  # Download (or load from cache)
  row <- match[base::nrow(match), ]
  destfile <- base::file.path(output_dir, row$filename)

  if (!base::file.exists(destfile)) {
    base::message("Downloading: ", row$filename)
    httr::GET(
      row$url,
      httr::add_headers(`User-Agent` = "Mozilla/5.0"),
      httr::write_disk(destfile, overwrite = TRUE),
      httr::progress()
    )
  } else {
    base::message("Loading from cache: ", destfile)
  }

  # Unpack archive
  unzip_dir <- base::file.path(output_dir, "data_unzip", base::format(target_date, "%Y-%m-%d"))
  if (!base::dir.exists(unzip_dir)) base::dir.create(unzip_dir, recursive = TRUE)
  utils::untar(destfile, exdir = unzip_dir)

  shp_files <- base::list.files(unzip_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
  if (base::length(shp_files) == 0) {
    stop("No shapefile found in the archive: ", destfile, call. = FALSE)
  }

  # Load, add unique IDs, reorder columns
  ice <- sf::st_read(shp_files[1], quiet = TRUE)
  ice$ID_NEW <- base::seq_len(base::nrow(ice))
  ice <- ice[, c("ID_NEW", base::setdiff(base::names(ice), c("ID_NEW", "geometry")), "geometry")]

  # save as gpkg with the new IDs
  final_gpkg <- base::file.path(
    output_dir,
    base::paste0(tools::file_path_sans_ext(base::basename(shp_files[1])), "_with_new_id.gpkg")
  )
  sf::st_write(ice, final_gpkg, delete_dsn = TRUE, quiet = TRUE)
  base::message("CIS Ice Chart written to: ", final_gpkg)

  # attach Metadata as attribute
  base::attr(ice, "region")   <- region
  base::attr(ice, "datum")    <- target_date
  base::attr(ice, "filename") <- row$filename

  ice
}
