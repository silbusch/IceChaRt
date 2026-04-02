#' Download the Ice Chart and load it as an SF object and add unique IDs
#'
#' @param target_date Date as string in format "YYYY-MM-DD" or as date object
#' @param region Region (default: "Eastern_Arctic")
#' @param output_dir Directory to cache (default: NULL --> using working directory)
#' @return sf-object with ice chart polygons and unique IDs
#' @export
downloadCISIceChart <- function(target_date = "2020-11-02",
                               region     = "Eastern_Arctic",
                               output_dir  = NULL) {

  target_date <- as.Date(target_date)
  year      <- format(target_date, "%Y")
  files     <- searchCISfiles(region, year)

  match <- files[files$datum == target_date & files$standard, ]

  if (nrow(match) == 0) {
    stop("No Chart for ", target_date, " in region '", region, "' found.\n",
         "Please select one of the alternative date: ", paste(files$datum[files$standard], collapse = ", "))
  }
  # create output Folder for CIS Ice charts
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

  row <- match[nrow(match), ]
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
  outdir <- file.path(output_dir, "data_unzip", format(target_date, "%Y-%m-%d"))
  if (!dir.exists(outdir))dir.create(outdir, recursive = TRUE)

  utils::untar(destfile, exdir = outdir)

  shp_files <- list.files(
    outdir,
    pattern = "\\.shp$",
    full.names = TRUE,
    recursive = TRUE
  )

  if (length(shp_files) == 0) stop("No shapefile found in the archive: ", destfile)

  ice <- sf::st_read(shp_files[1], quiet = TRUE)

  # Create unique IDs
  ice$ID_NEW <- seq_len(nrow(ice))
  # ID as first column
  ice <- ice[, c("ID_NEW", setdiff(names(ice), c("ID_NEW", "geometry")), "geometry")]

  # save as gpkg with the new IDs
  final_gpkg <- file.path(
    output_dir,
    paste0(tools::file_path_sans_ext(basename(shp_files[1])), "_with_new_id.gpkg")
  )

  sf::st_write(ice, final_gpkg, delete_dsn = TRUE, quiet = TRUE)

  message("CIS Ice Chart with written to: ", final_gpkg)

  # Metadata as attribute
  attr(ice, "region")    <- region
  attr(ice, "datum")     <- target_date
  attr(ice, "filename") <- row$filename

  ice
}
