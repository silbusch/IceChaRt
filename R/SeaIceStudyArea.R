#' Clip a SpatVector (the IceChart) to the extent of a SpatRaster
#'
#' Takes a vector dataset and a raster dataset, checks whether
#' their coordinate reference systems (CRS) match, and reprojects the raster to
#' the CRS of the vector if necessary. The vector is then cropped to the raster extent.
#'
#' @param shp A `terra::SpatVector` object (e.g. loaded via `terra::vect("path/to/file.shp")`).
#' @param tif A `terra::SpatRaster` object (e.g. loaded via `terra::rast("path/to/file.tif")`).
#' @param out_path Optional output path for the cropped vector file. If `NULL`, no file is written.
#'
#' @return A `terra::SpatVector` containing the cropped vector.
#'
#' @details
#' If the raster has no CRS, the CRS of the vector is assigned to the raster.
#' If both datasets have different CRS definitions, the raster is reprojected to
#' the CRS of the vector using `terra::project()`.
#'
#' @export
#To-Do: Need to describe function
# To-Do: Maybe deleting Land polygones is not smart

SeaIceStudyArea <- function(shp, tif, save = TRUE, out_path = NULL, out_dir = NULL, land_mask = TRUE, land_col = "POLY_TYPE", land_val= "L") {
  # Input validation
  if (!inherits(shp, "SpatVector")) {
    stop("'shp' must be a terra::SpatVector object. Load it with terra::vect().", call. = FALSE)
  }
  if (!inherits(tif, "SpatRaster")) {
    stop("'tif' must be a terra::SpatRaster object. Load it with terra::rast().", call. = FALSE)
  }

  # out_path validation
  if (!is.null(out_path)) {
    supported_formats <- c(".shp", ".gpkg", ".geojson", ".json", ".kml", ".gml", ".fgb")
    ext <- tolower(tools::file_ext(out_path))
    ext <- paste0(".", ext)

    if (!ext %in% supported_formats) {
      stop(
        "Unsupported output format: '", ext, "'.\n",
        "Supported formats: ", paste(supported_formats, collapse = ", "),
        call. = FALSE
      )
    }
  }

  # land_mask validation
  if (land_mask) {
    if (!land_col %in% names(shp)) {
      stop("Column '", land_col, "' not found in SpatVector. Available columns: ",
           paste(names(shp), collapse = ", "), call. = FALSE)
    }
    land_polygons <- shp[shp[[land_col]] == land_val, ]
    if (nrow(land_polygons) == 0) {
      warning("No polygons with '", land_col, " == ", land_val, "' found. Land mask skipped.")
      land_mask <- FALSE
    }
  }

  shp_crs <- terra::crs(shp)
  tif_crs <- terra::crs(tif)

  message("CRS SpatVector:\n", shp_crs, "\n")
  message("CRS SpatRaster:\n", tif_crs, "\n")

  if (is.na(shp_crs) || shp_crs == "") {
    stop("The SpatVector has no defined coordinate reference system.", call. = FALSE)
  }

  if (is.na(tif_crs) || tif_crs == "") {
    message("The SpatRaster has no defined CRS. Assigning the CRS of the SpatVector.")
    terra::crs(tif) <- shp_crs
  } else if (shp_crs != tif_crs) {
    message("CRS do not match. Reprojecting SpatRaster to the CRS of the SpatVector.")
    tif <- terra::project(tif, shp_crs)
  } else {
    message("CRS match.")
  }

  tif_ext     <- terra::ext(tif)
  shp_clipped <- terra::crop(shp, tif_ext)

  #Land mask
  if (land_mask) {
    message("Applying land mask using '", land_col, " == ", land_val, "'...")
    land_polygons <- terra::crop(land_polygons, tif_ext)
    tif <- terra::mask(tif, land_polygons, inverse = TRUE)
    message("Land mask applied.")
  }

  if (!is.null(out_path)) {
    terra::writeVector(shp_clipped, out_path, overwrite = TRUE)
    message("Cropped vector written to: ", out_path)
  }

  #output with timestamp
  if (save) {
    save_dir <- if (!is.null(out_dir)) out_dir else file.path(getwd(), "IceChaRt_output")

    if (!dir.exists(save_dir)) {
      dir.create(save_dir, recursive = TRUE)
      message("Created output directory: ", save_dir)
    }
    ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
    shp_file <- if (!is.null(out_path)) {
      out_path
    } else {
      file.path(save_dir, paste0("clipped_icechart_", ts, ".gpkg"))
    }
    terra::writeVector(shp_clipped, shp_file, overwrite = TRUE)
    message("Vector written to: ", shp_file)

    if (land_mask) {
      tif_file <- file.path(save_dir, paste0("masked_raster_", ts, ".tif"))
      terra::writeRaster(tif, tif_file, overwrite = TRUE)
      message("Raster written to: ", tif_file)
    }
  }
  list(
    shp = shp_clipped,
    tif = tif
  )
}
