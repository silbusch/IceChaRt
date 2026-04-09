#' Create a Sea Ice RGB Composite from Sentinel-1 dual-polarization SAR data
#'
#' Generates a false-colour RGB composite from preprocessed Sentinel-1
#' co-polarization and cross-polarization channels following the
#' Sentinel Hub SAR-Ice script by Martin Raspaud and Mikhail Itkin.
#' \url{https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/}
#'
#' @param co_pol       A \code{terra::SpatRaster} containing the co-polarized
#'                     backscatter band. For EW mode: HH. For IW mode: VV.
#' @param cross_pol    A \code{terra::SpatRaster} containing the cross-polarized
#'                     backscatter band. For EW mode: HV. For IW mode: VH.
#' @param mode         Character. Acquisition mode: \code{"EW"} (default) or
#'                     \code{"IW"}. Controls only the output filename suffix
#'                     when \code{output_path} is \code{NULL}; the actual
#'                     band assignment is always determined by what you pass
#'                     to \code{co_pol} / \code{cross_pol}.
#' @param datatype     Character. Output data type for the GeoTIFF. One of
#'                     \code{"INT1U"} (8-bit unsigned integer, values scaled to
#'                     0--255, recommended for visualisation),
#'                     \code{"INT2U"} (16-bit unsigned integer, values scaled to
#'                     0--10000, recommended for further processing), or
#'                     \code{"FLT4S"} (32-bit float, values kept at 0--1).
#'                     Default: \code{"INT1U"}.
#' @param input_in_db  Logical. If \code{TRUE}, input values are assumed to be
#'                     in dB and will be converted to linear scale before
#'                     processing. Default: \code{FALSE}.
#' @param nodata       Numeric. NoData value to mask. If \code{NULL}, the
#'                     value stored in the raster metadata is used.
#' @param nodata_tol   Numeric. Tolerance for floating-point NoData comparison.
#'                     Default: \code{1e-3}.
#' @param output_path  Optional path for saving the output as a GeoTIFF raster.
#'                     If \code{NULL}, the file is saved to
#'                     \code{IceChaRt_output/s1_rgb/} in the working directory
#'                     with an auto-generated name including mode and timestamp.
#'                     If no \code{.tif} suffix is given, it will be added.
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
#' Output scaling by datatype:
#' \tabular{lll}{
#'   \strong{datatype} \tab \strong{Scale factor} \tab \strong{Value range} \cr
#'   INT1U             \tab 255                   \tab 0--255               \cr
#'   INT2U             \tab 10000                 \tab 0--10000             \cr
#'   FLT4S             \tab 1 (none)              \tab 0--1                 \cr
#' }
#'
#' @examples
#' \dontrun{
#' # Download the test data
#' download_testdata_IceChaRt()
#'
#' # load raster
#' co_pol_path    <- system.file("extdata", "s1_20201101_hh.tif", package = "IceChaRt")
#' cross_pol_path <- system.file("extdata", "s1_20201101_hv.tif", package = "IceChaRt")
#'
#' co_pol    <- terra::rast(co_pol_path)
#' cross_pol <- terra::rast(cross_pol_path)
#'
#' # EW mode (HH / HV), default INT1U output
#' s1_seaice_rgb(co_pol = co_pol, cross_pol = cross_pol, mode = "EW")
#' }
#'
#' @export

s1_seaice_rgb <- function(co_pol,
                          cross_pol,
                          mode        = base::c("EW", "IW"),
                          datatype    = base::c("INT2U", "INT1U", "FLT4S"),
                          input_in_db = FALSE,
                          nodata      = NULL,
                          nodata_tol  = 1e-3,
                          output_path = NULL) {

  mode <- base::match.arg(mode)
  datatype <- base::match.arg(datatype)

  #--- Input validation --------------------------------------------------------
  if (!base::inherits(co_pol, "SpatRaster")) {
    base::stop("'co_pol' must be a terra::SpatRaster")
  }
  if (!base::inherits(cross_pol, "SpatRaster")) {
    base::stop("'cross_pol' must be a terra::SpatRaster")
  }
  if (terra::nlyr(co_pol) != 1L) {
    base::stop("'co_pol' must have exactly one layer")
  }
  if (terra::nlyr(cross_pol) != 1L) {
    base::stop("'cross_pol' must have exactly one layer")
  }
  if (!terra::compareGeom(co_pol, cross_pol, stopOnError = FALSE)) {
    base::stop("'co_pol' and 'cross_pol' must have the same extent, resolution, and CRS")
  }

  #--- NoData masking ----------------------------------------------------------
  nodata_co <- if (!base::is.null(nodata)) nodata else terra::NAflag(co_pol)
  nodata_cross <- if (!base::is.null(nodata)) nodata else terra::NAflag(cross_pol)

  .mask_nodata <- function(r, nd) {
    if (base::length(nd) == 1L && !base::is.na(nd) && !base::is.nan(nd)) {
      terra::classify(
        r,
        rcl = base::matrix(base::c(nd - nodata_tol, nd + nodata_tol, NA_real_), nrow = 1L),
        include.lowest = TRUE
      )
    } else {
      r
    }
  }

  co_pol <- .mask_nodata(co_pol,    nodata_co)
  cross_pol <- .mask_nodata(cross_pol, nodata_cross)

  #--- dB → linear conversion (optional) ---------------------------------------
  if (input_in_db) {
    co_pol <- 10 ^ (co_pol    / 10)
    cross_pol <- 10 ^ (cross_pol / 10)
  }

  #--- Physical plausibility clamp ---------------------------------------------
  co_pol <- terra::ifel(co_pol    < -0.002, NA, co_pol)
  cross_pol <- terra::ifel(cross_pol < -0.002, NA, cross_pol)

  #--- Helper functions --------------------------------------------------------
  .stretch <- function(r, vmin, vmax) {
    terra::clamp((r - vmin) / (vmax - vmin), 0, 1)
  }

  .gamma <- function(r, gamma = 1.1) {
    terra::clamp(r, 0, 1) ^ (1 / gamma)
  }

  #--- RGB computation ---------------------------------------------------------
  #   EW: co_pol = HH, cross_pol = HV
  #   IW: co_pol = VV, cross_pol = VH
  m_cross <- base::sqrt(cross_pol + 0.002)
  m_co    <- base::sqrt(co_pol    + 0.002)
  ov      <- ((1 - 2 * m_co) * m_cross + 2 * m_co) * m_cross

  red   <- .gamma(.stretch(m_cross, 0.02, 0.10))
  green <- .gamma(.stretch(ov,      0.00, 0.06))
  blue  <- .gamma(.stretch(m_co,    0.00, 0.32))

  rgb_stack        <- base::c(red, green, blue)
  base::names(rgb_stack) <- base::c("red", "green", "blue")

  #--- Output scaling ----------------------------------------------------------
  scale_factor <- base::switch(datatype,
                               INT1U = 255,
                               INT2U = 10000,
                               FLT4S = 1
  )

  #--- Output path handling ----------------------------------------------------
  if (base::is.null(output_path)) {
    main_dir <- base::file.path(base::getwd(), "IceChaRt_output")
    output_dir <- base::file.path(main_dir, "s1_rgb")

    for (d in base::c(main_dir, output_dir)) {
      if (!base::dir.exists(d)) {
        base::dir.create(d, recursive = TRUE)
        base::message("Created directory: ", d)
      }
    }

    timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
    filename <- base::paste0("sea_ice_rgb_", base::tolower(mode), "_", timestamp, ".tif")
    output_path <- base::file.path(output_dir, filename)

  } else {
    output_dir <- base::dirname(output_path)

    if (!base::dir.exists(output_dir)) {
      base::dir.create(output_dir, recursive = TRUE)
      base::message("Created output directory: ", output_dir)
    }

    if (!base::grepl("\\.(tif|tiff)$", output_path, ignore.case = TRUE)) {
      output_path <- base::paste0(output_path, ".tif")
    }
  }

  #--- Write output ------------------------------------------------------------
  terra::writeRaster(
    rgb_stack * scale_factor,
    output_path,
    filetype = "GTiff",
    datatype = datatype,
    overwrite = TRUE
  )

  base::message(
    "RGB composite (", mode, " mode, ", datatype, ") written to: ", output_path
  )

  base::invisible(rgb_stack)
}
