#' Clip a SpatVector (the IceChart) to the extent of a SpatRaster and optionally mask land areas
#'
#' Takes a vector and a raster dataset, checks whether their coordinate reference
#' systems (CRS) match, and reprojects the raster to the CRS of the vector if
#' necessary. The vector is then cropped to the raster extent. Optionally, land
#' polygons are used to mask the land from the raster.
#'
#' @param shp A `terra::SpatVector` object (e.g. loaded via `terra::vect("path/to/file.shp")`).
#' @param tif A `terra::SpatRaster` object (e.g. loaded via `terra::rast("path/to/file.tif")`).
#' @param out_path Optional output path for the cropped vector file (e.g. `"output/study_area.gpkg"`).
#'   Supported formats: `.shp`, `.gpkg`, `.geojson`, `.json`, `.kml`, `.gml`, `.fgb`.
#'   If `NULL`, output is saved automatically to `IceChaRt_output/study_area/`.
#' @param out_dir Optional base directory for automatic output. If `NULL`, the current
#'   working directory is used. Ignored when `out_path` is provided.
#' @param land_mask Logical. If `TRUE` (default), land polygons are masked from
#'   the raster. The vector is not affected.
#' @param land_col Character. Name of the column in `shp` used to identify land polygons.
#'   Defaults to `"POLY_TYPE"`.
#' @param land_val Character. Value in `land_col` that identifies land polygons.
#'   Defaults to `"L"`.
#'
#' @return A named list with two elements:
#' \describe{
#'   \item{`shp`}{A `terra::SpatVector` with the cropped (and optionally land-masked) vector.}
#'   \item{`tif`}{A `terra::SpatRaster` with the (optionally land-masked) raster.}
#' }
#'
#' @details
#' If the raster has no CRS, the CRS of the vector is assigned to it.
#' If both datasets have differing CRS definitions, the raster is reprojected to
#' the CRS of the vector using `terra::project()`.
#' If `land_mask = TRUE`, the masked raster is saved alongside the vector.
#' Land masking applies only to the raster, the vector keeps all polygon types.
#'
#' Output is always written to disk. If `out_path` is `NULL`, files are saved to
#' `IceChaRt_output/study_area/` (relative to `out_dir` or the working directory),
#' with a timestamp appended to the filename. If `land_mask = TRUE`, the masked
#' raster is saved alongside the vector.
#'
#' @export

seaice_studyarea <- function(shp, tif, save = TRUE, out_path = NULL, out_dir = NULL, land_mask = TRUE, land_col = "POLY_TYPE", land_val= "L") {
  # Input validation
  if (!inherits(shp, "SpatVector")) {
    stop("'shp' must be a terra::SpatVector object. Load it with terra::vect().", call. = FALSE)
  }
  if (!inherits(tif, "SpatRaster")) {
    stop("'tif' must be a terra::SpatRaster object. Load it with terra::rast().", call. = FALSE)
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

  # Crop & land mask
  tif_ext     <- terra::ext(tif)
  shp_clipped <- terra::crop(shp, tif_ext)

  if (land_mask) {
    message("Applying land mask using '", land_col, " == ", land_val, "'...")
    land_polygons <- terra::crop(land_polygons, tif_ext)
    tif <- terra::mask(tif, land_polygons, inverse = TRUE)
    message("Land mask applied.")
  }

    # Output path handling
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

    if (is.null(out_path)) {
      main_dir   <- file.path(if (!is.null(out_dir)) out_dir else getwd(), "IceChaRt_output")
      output_dir <- file.path(main_dir, "study_area")
      for (d in c(main_dir, output_dir)) {
        if (!dir.exists(d)) {
          dir.create(d, recursive = TRUE)
          message("Created directory: ", d)
        }
      }
      shp_file <- file.path(output_dir, paste0("clipped_icechart_", timestamp, ".gpkg"))
      tif_file <- file.path(output_dir, paste0("masked_raster_",   timestamp, ".tif"))
    } else {

      # Validate format
      supported_formats <- c(".shp", ".gpkg", ".geojson", ".json", ".kml", ".gml", ".fgb")
      ext <- paste0(".", tolower(tools::file_ext(out_path)))
      if (!ext %in% supported_formats) {
        stop("Unsupported output format: '", ext, "'.\n",
             "Supported formats: ", paste(supported_formats, collapse = ", "), call. = FALSE)
      }
      output_dir <- dirname(out_path)
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
        message("Created output directory: ", output_dir)
      }
      shp_file <- out_path
      tif_file <- file.path(output_dir, paste0("masked_raster_", timestamp, ".tif"))
    }

    terra::writeVector(shp_clipped, shp_file, overwrite = TRUE)
    message("Vector written to: ", shp_file)

    if (land_mask) {
      terra::writeRaster(tif, tif_file, overwrite = TRUE)
      message("Raster written to: ", tif_file)
    }

    list(shp = shp_clipped, tif = tif)
  }
