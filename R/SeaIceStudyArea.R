#' Clip a shapefile (the IceChart) to the extent of a TIFF raster
#'
#' Loads a vector dataset and a raster dataset, checks whether their coordinate
#' reference systems (CRS) match, and reprojects the raster to the CRS of the
#' shapefile if necessary. The shapefile is then cropped to the raster extent.
#'
#' @param shp_path Path to the input shapefile or other vector file.
#' @param tif_path  Path to the input TIFF raster.
#' @param out_path Output path for the cropped vector file.
#'
#' @return A `terra::SpatVector` containing the cropped shapefile.
#'
#' @details
#' If the raster has no CRS, the CRS of the shapefile is assigned to the raster.
#' If both datasets have different CRS definitions, the raster is reprojected to
#' the CRS of the shapefile using `terra::project()`.
#'
#' @export

SeaIceStudyArea <- function(shp_path, tif_path, out_path = NULL) {
  shp <- terra::vect(shp_path)
  tif <- terra::rast(tif_path)

  shp_crs <- terra::crs(shp)
  tif_crs <- terra::crs(tif)

  message("CRS Shapefile:\n", shp_crs, "\n")
  message("CRS TIFF:\n", tif_crs, "\n")

  if (is.na(shp_crs) || shp_crs == "") {
    stop("The shapefile has no defined coordinate reference system.", call. = FALSE)
  }

  if (is.na(tif_crs) || tif_crs == "") {
    message("The TIFF has no defined CRS. Assigning the CRS of the shapefile.")
    terra::crs(tif) <- shp_crs
  } else if (shp_crs != tif_crs) {
    message("CRS do not match. Reprojecting TIFF to the CRS of the shapefile.")
    tif <- terra::project(tif, shp_crs)
  } else {
    message("CRS match.")
  }

  tif_ext <- terra::ext(tif)
  shp_clipped <- terra::crop(shp, tif_ext)

  if (!is.null(out_path)) {
    terra::writeVector(shp_clipped, out_path, overwrite = TRUE)
    message("Cropped shapefile written to: ", out_path)
  }

  shp_clipped
}

# To-Do: Want to include optional land mask clipping with osmdata in this function too
