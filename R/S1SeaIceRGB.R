#' Create a Sea Ice RGB Composite from Sentinel-1 dual-polarization SAR data
#'
#' Generates a false-colour RGB composite from preprocessed Sentinel-1
#' co-polarization and cross-polarization channels following the
#' Sentinel Hub SAR-Ice script by Martin Raspaud and Mikhail Itkin.
#' \url{https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/}
#'
#' @param co_pol       A \code{terra::SpatRaster} containing the co-polarized
#'                     backscatter band. For EW mode: HH. For IW mode: VV.
#'                     Ignored if \code{mode} is \code{"EW"} or \code{"IW"}
#'                     and \code{ew_hh}/\code{ew_hv}/\code{iw_vv}/\code{iw_vh}
#'                     are provided via the named helpers. See Details.
#' @param cross_pol    A \code{terra::SpatRaster} containing the cross-polarized
#'                     backscatter band. For EW mode: HV. For IW mode: VH.
#' @param mode         Character. Acquisition mode: \code{"EW"} (default) or
#'                     \code{"IW"}. Controls only the output filename suffix
#'                     when \code{output_path} is \code{NULL}; the actual
#'                     band assignment is always determined by what you pass
#'                     to \code{co_pol} / \code{cross_pol}.
#' @param input_in_db  Logical. If \code{TRUE}, input values are assumed to be
#'                     in dB and will be converted to linear scale before
#'                     processing. Default: \code{FALSE}.
#' @param nodata       Numeric. NoData value to mask. If \code{NULL}, the
#'                     value stored in the raster metadata is used.
#' @param nodata_tol   Numeric. Tolerance for floating-point NoData comparison.
#'                     Default: \code{1e-3}.
#' @param output_path  Optional path for saving the output as a GeoTIFF
#'                     raster. If no \code{.tif} suffix is given, it will be
#'                     added.
#'
#' @return A \code{terra::SpatRaster} with three bands (red, green, blue),
#'         values scaled to the range 0--1. Returned invisibly.
#'
#' @details
#' The RGB channels are derived as follows:
#' \itemize{
#'   \item \strong{Red}:   stretched square root of the cross-polarized band
#'                         (HV for EW, VH for IW)
#'   \item \strong{Green}: stretched interaction term combining co- and
#'                         cross-polarized backscatter (Overlay blend)
#'   \item \strong{Blue}:  stretched square root of the co-polarized band
#'                         (HH for EW, VV for IW)
#' }
#' All channels are gamma-corrected (gamma = 1.1) and linearly stretched
#' to the 0--1 range before output.
#'
#' Band assignment by mode:
#' \tabular{lll}{
#'   \strong{Mode} \tab \strong{co_pol} \tab \strong{cross_pol} \cr
#'   EW            \tab HH              \tab HV                 \cr
#'   IW            \tab VV              \tab VH                 \cr
#' }
#'
#' @examples
#' \dontrun{
#' # EW mode (HH / HV)
#' rgb_ew <- seaIceRGB(co_pol = hh_raster, cross_pol = hv_raster, mode = "EW")
#'
#' # IW mode (VV / VH)
#' rgb_iw <- seaIceRGB(co_pol = vv_raster, cross_pol = vh_raster, mode = "IW")
#' }
#'
#' @export
seaIceRGB <- function(co_pol,
                      cross_pol,
                      mode        = c("EW", "IW"),
                      input_in_db = FALSE,
                      nodata      = NULL,
                      nodata_tol  = 1e-3,
                      output_path = NULL) {

  mode <- match.arg(mode)

# Input validation
  if (!inherits(co_pol, "SpatRaster")) {
    stop("'co_pol' must be a terra::SpatRaster")
  }
  if (!inherits(cross_pol, "SpatRaster")) {
    stop("'cross_pol' must be a terra::SpatRaster")
  }
  if (terra::nlyr(co_pol) != 1L) {
    stop("'co_pol' must have exactly one layer")
  }
  if (terra::nlyr(cross_pol) != 1L) {
    stop("'cross_pol' must have exactly one layer")
  }
  if (!terra::compareGeom(co_pol, cross_pol, stopOnError = FALSE)) {
    stop("'co_pol' and 'cross_pol' must have the same extent, resolution, and CRS")
  }

# NoData masking
  nodata_co    <- if (!is.null(nodata)) nodata else terra::NAflag(co_pol)
  nodata_cross <- if (!is.null(nodata)) nodata else terra::NAflag(cross_pol)

  .mask_nodata <- function(r, nd) {
    if (length(nd) == 1L && !is.na(nd) && !is.nan(nd)) {
      terra::classify(
        r,
        rcl = matrix(c(nd - nodata_tol, nd + nodata_tol, NA_real_), nrow = 1L),
        include.lowest = TRUE
      )
    } else {
      r
    }
  }

  co_pol    <- .mask_nodata(co_pol,    nodata_co)
  cross_pol <- .mask_nodata(cross_pol, nodata_cross)

# dB → linear conversion (optional)
  if (input_in_db) {
    co_pol    <- 10 ^ (co_pol    / 10)
    cross_pol <- 10 ^ (cross_pol / 10)
  }

# Physical plausibility clamp
  co_pol    <- terra::ifel(co_pol    < -0.002, NA, co_pol)
  cross_pol <- terra::ifel(cross_pol < -0.002, NA, cross_pol)

# Helper functions
  .stretch <- function(r, vmin, vmax) {
    terra::clamp((r - vmin) / (vmax - vmin), 0, 1)
  }

  .gamma <- function(r, gamma = 1.1) {
    terra::clamp(r, 0, 1) ^ (1 / gamma)
  }

# RGB computation (identical for EW and IW — only input bands differ)
  #   EW: co_pol = HH, cross_pol = HV
  #   IW: co_pol = VV, cross_pol = VH
  m_cross <- sqrt(cross_pol + 0.002)   # mhv  (EW) / mvh  (IW)
  m_co    <- sqrt(co_pol    + 0.002)   # mhh  (EW) / mvv  (IW)
  ov      <- ((1 - 2 * m_co) * m_cross + 2 * m_co) * m_cross  # Overlay blend

  red   <- .gamma(.stretch(m_cross, 0.02, 0.10))
  green <- .gamma(.stretch(ov,      0.00, 0.06))
  blue  <- .gamma(.stretch(m_co,    0.00, 0.32))

  rgb_stack        <- c(red, green, blue)
  names(rgb_stack) <- c("red", "green", "blue")

# Output path handling
  if (is.null(output_path)) {
    main_dir   <- file.path(getwd(), "IceChaRt_output")
    output_dir <- file.path(main_dir, "rgb")

    for (d in c(main_dir, output_dir)) {
      if (!dir.exists(d)) {
        dir.create(d, recursive = TRUE)
        message("Created directory: ", d)
      }
    }

    timestamp   <- format(Sys.time(), "%Y%m%d_%H%M%S")
    filename    <- paste0("sea_ice_rgb_", tolower(mode), "_", timestamp, ".tif")
    output_path <- file.path(output_dir, filename)

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
# Write output
  terra::writeRaster(
    rgb_stack,
    output_path,
    filetype  = "GTiff",
    datatype  = "FLT4S",
    overwrite = TRUE
  )

  message("RGB composite (", mode, " mode) written to: ", output_path)

  invisible(rgb_stack)
}
