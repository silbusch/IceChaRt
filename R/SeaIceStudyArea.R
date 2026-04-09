#' Clip a SpatVector (the IceChart) to the extent of a SpatRaster and optionally mask land areas
#'
#' Takes a vector and a raster dataset, checks whether their coordinate reference
#' systems (CRS) match, and reprojects the raster to the CRS of the vector if
#' necessary. The vector is then cropped to the raster extent. Optionally, land
#' polygons are used to mask the land from the raster.
#'
#' @param shp A `terra::SpatVector` object (e.g. loaded via `terra::vect("path/to/file.shp")`).
#' @param tif A `terra::SpatRaster` object (e.g. loaded via `terra::rast("path/to/file.tif")`).
#' @param save If \code{TRUE}, created `SpatVector` and `SpatRaster` will be saved.
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
#' @examples
#' \dontrun{
#' # Download the test data
#'download_testdata_IceChaRt()
#'
#'# load raster
#'co_pol_path    <- system.file("extdata", "s1_20201101_hh.tif", package = "IceChaRt")
#'cross_pol_path <- system.file("extdata", "s1_20201101_hv.tif", package = "IceChaRt")
#'
#'s1_hh    <- terra::rast(co_pol_path)
#'s1_hv <- terra::rast(cross_pol_path)
#'
#'path <- system.file("extdata", "cis_SGRDREA_20201102T.gpkg", package = "IceChaRt")
#'ice_chart <- terra::vect(path)
#'
#'seaice_studyarea(shp = ice_chart, tif = s1_hh)
#'seaice_studyarea(shp = ice_chart, tif = s1_hv)
#'
#' }
#' @export

seaice_studyarea <- function(shp, tif, save = TRUE, out_path = NULL, out_dir = NULL, land_mask = TRUE, land_col = "POLY_TYPE", land_val= "L") {
  # Input validation
  if (!base::inherits(shp, "SpatVector")) {
    base::stop("'shp' must be a terra::SpatVector object. Load it with terra::vect().", call. = FALSE)
  }
  if (!base::inherits(tif, "SpatRaster")) {
    base::stop("'tif' must be a terra::SpatRaster object. Load it with terra::rast().", call. = FALSE)
  }

  # land_mask validation
  if (land_mask) {
    if (!land_col %in% base::names(shp)) {
      base::stop("Column '", land_col, "' not found in SpatVector. Available columns: ",
                 base::paste(base::names(shp), collapse = ", "), call. = FALSE)
    }
    land_polygons <- shp[shp[[land_col]] == land_val, ]
    if (base::nrow(land_polygons) == 0) {
      base::warning("No polygons with '", land_col, " == ", land_val, "' found. Land mask skipped.")
      land_mask <- FALSE
    }
  }

  shp_crs <- terra::crs(shp)
  tif_crs <- terra::crs(tif)

  base::message("CRS SpatVector:\n", shp_crs, "\n")
  base::message("CRS SpatRaster:\n", tif_crs, "\n")

  if (base::is.na(shp_crs) || shp_crs == "") {
    base::stop("The SpatVector has no defined coordinate reference system.", call. = FALSE)
  }

  if (base::is.na(tif_crs) || tif_crs == "") {
    base::message("The SpatRaster has no defined CRS. Assigning the CRS of the SpatVector.")
    terra::crs(tif) <- shp_crs
  } else if (shp_crs != tif_crs) {
    base::message("CRS do not match. Reprojecting SpatRaster to the CRS of the SpatVector.")
    tif <- terra::project(tif, shp_crs)
  } else {
    base::message("CRS match.")
  }

  # Crop & land mask
  tif_ext     <- terra::ext(tif)
  shp_clipped <- terra::crop(shp, tif_ext)

  if (land_mask) {
    base::message("Applying land mask using '", land_col, " == ", land_val, "'...")
    land_polygons <- terra::crop(land_polygons, tif_ext)
    tif <- terra::mask(tif, land_polygons, inverse = TRUE)
    base::message("Land mask applied.")
  }

  # Output path handling
  timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")

  if (base::is.null(out_path)) {
    main_dir   <- base::file.path(if (!base::is.null(out_dir)) out_dir else base::getwd(), "IceChaRt_output")
    output_dir <- base::file.path(main_dir, "study_area")
    for (d in base::c(main_dir, output_dir)) {
      if (!base::dir.exists(d)) {
        base::dir.create(d, recursive = TRUE)
        base::message("Created directory: ", d)
      }
    }
    shp_file <- base::file.path(output_dir, base::paste0("clipped_icechart_", timestamp, ".gpkg"))
    tif_file <- base::file.path(output_dir, base::paste0("masked_raster_",   timestamp, ".tif"))
  } else {

    # Validate format
    supported_formats <- base::c(".shp", ".gpkg", ".geojson", ".json", ".kml", ".gml", ".fgb")
    ext <- base::paste0(".", base::tolower(tools::file_ext(out_path)))
    if (!ext %in% supported_formats) {
      base::stop("Unsupported output format: '", ext, "'.\n",
                 "Supported formats: ", base::paste(supported_formats, collapse = ", "), call. = FALSE)
    }
    output_dir <- base::dirname(out_path)
    if (!base::dir.exists(output_dir)) {
      base::dir.create(output_dir, recursive = TRUE)
      base::message("Created output directory: ", output_dir)
    }
    shp_file <- out_path
    tif_file <- base::file.path(output_dir, base::paste0("masked_raster_", timestamp, ".tif"))
  }

  terra::writeVector(shp_clipped, shp_file, overwrite = TRUE)
  base::message("Vector written to: ", shp_file)

  if (land_mask) {
    terra::writeRaster(tif, tif_file, overwrite = TRUE)
    base::message("Raster written to: ", tif_file)
  }

  base::list(shp = shp_clipped, tif = tif)
}
