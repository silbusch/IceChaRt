#' Create a Sea Ice RGB Composite from Sentinel-1 dual-polarization SAR data
#'
#' Generates a false-colour RGB composite from preprocessed Sentinel-1
#' co-polarization and cross-polarization channels following the
#' Sentinel Hub SAR-Ice script by Martin Raspaud and Mikhail Itkin.
#' \url{https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/}
#'
#' For EW mode, use HH as \code{co_pol} and HV as \code{cross_pol}.
#' For IW mode, use VV as \code{co_pol} and VH as \code{cross_pol}.
#'
#' @param co_pol       A \code{terra::SpatRaster} containing the co-polarized
#'                     backscatter band (HH for EW, VV for IW).
#' @param cross_pol    A \code{terra::SpatRaster} containing the cross-polarized
#'                     backscatter band (HV for EW, VH for IW).
#' @param input_in_db  Logical. If \code{TRUE}, input values are assumed to be
#'                     in dB and will be converted to linear scale before
#'                     processing. Default: \code{FALSE}.
#' @param nodata       Numeric. NoData value to mask. If \code{NULL}, the
#'                     value stored in the raster metadata is used.
#' @param nodata_tol   Numeric. Tolerance for floating-point NoData comparison.
#'                     Default: \code{1e-3}.
#' @param output_path  Optional path for saving the output as a GeoTIFF
#'                     raster. If no \code{.tif} suffix is given, it will be added.
#'
#' @return A \code{terra::SpatRaster} with three bands (red, green, blue),
#'         values scaled to the range 0--1. Returned invisibly.
#'
#' @details
#' The RGB channels are derived as follows:
#' \itemize{
#'   \item \strong{Red}: stretched square root of cross-polarized backscatter
#'   \item \strong{Green}: stretched interaction term combining co- and cross-polarized backscatter
#'   \item \strong{Blue}: stretched square root of co-polarized backscatter
#' }
#' All channels are gamma-corrected (gamma = 1.1) and linearly stretched
#' to the 0--1 range before output.
#'
#' @export
seaIceRGB <- function(co_pol,
                      cross_pol,
                      input_in_db = FALSE,
                      nodata      = NULL,
                      nodata_tol  = 1e-3,
                      output_path = NULL) {

  if (!inherits(co_pol, "SpatRaster")) {
    stop("'co_pol' must be a terra::SpatRaster")
  }
  if (!inherits(cross_pol, "SpatRaster")) {
    stop("'cross_pol' must be a terra::SpatRaster")
  }
  if (terra::nlyr(co_pol) != 1) {
    stop("'co_pol' must have exactly one layer")
  }
  if (terra::nlyr(cross_pol) != 1) {
    stop("'cross_pol' must have exactly one layer")
  }
  if (!terra::compareGeom(co_pol, cross_pol, stopOnError = FALSE)) {
    stop("'co_pol' and 'cross_pol' must have the same extent, resolution, and CRS")
  }

  nodata_co_pol <- if (!is.null(nodata)) nodata else terra::NAflag(co_pol)
  nodata_cross_pol <- if (!is.null(nodata)) nodata else terra::NAflag(cross_pol)

  .mask_nodata <- function(r, nd) {
    if (!is.null(nd) && length(nd) == 1 && !is.nan(nd) && !is.na(nd)) {
      terra::classify(
        r,
        rcl = matrix(c(nd - nodata_tol, nd + nodata_tol, NA_real_), nrow = 1),
        include.lowest = TRUE
      )
    } else {
      r
    }
  }

  co_pol <- .mask_nodata(co_pol, nodata_co_pol)
  cross_pol <- .mask_nodata(cross_pol, nodata_cross_pol)

  if (input_in_db) {
    co_pol <- 10 ^ (co_pol / 10)
    cross_pol <- 10 ^ (cross_pol / 10)
  }

  co_pol <- terra::ifel(co_pol < -0.002, NA, co_pol)
  cross_pol <- terra::ifel(cross_pol < -0.002, NA, cross_pol)

  .stretch <- function(r, vmin, vmax) {
    terra::clamp((r - vmin) / (vmax - vmin), 0, 1)
  }

  .gamma <- function(r, gamma = 1.1) {
    terra::clamp(r, 0, 1) ^ (1 / gamma)
  }

  mhv <- sqrt(cross_pol + 0.002)
  mhh <- sqrt(co_pol + 0.002)
  ov  <- ((1 - 2 * mhh) * mhv + 2 * mhh) * mhv

  red   <- .gamma(.stretch(mhv, 0.02, 0.10))
  green <- .gamma(.stretch(ov,  0.00, 0.06))
  blue  <- .gamma(.stretch(mhh, 0.00, 0.32))

  rgb_stack <- c(red, green, blue)
  names(rgb_stack) <- c("red", "green", "blue")

  if (is.null(output_path)) {
    main_dir <- file.path(getwd(), "IceChaRt_output")
    output_dir <- file.path(main_dir, "rgb")

    if (!dir.exists(main_dir)) {
      dir.create(main_dir, recursive = TRUE)
      message("Created output directory: ", main_dir)
    }

    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
      message("Created subdirectory: ", output_dir)
    }

    output_path <- file.path(output_dir, "sea_ice_rgb.tif")
  } else {
    output_dir <- dirname(output_path)

    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
      message("Created output directory: ", output_dir)
    }

    if (!grepl("\\.(tif|tiff)$", output_path, ignore.case = TRUE)) {
      output_path <- paste0(output_path, ".tif")
    }
  }

  terra::writeRaster(
    rgb_stack,
    output_path,
    filetype = "GTiff",
    datatype = "FLT4S",
    overwrite = TRUE
  )

  message("RGB composite written to: ", output_path)

  invisible(rgb_stack)
}
