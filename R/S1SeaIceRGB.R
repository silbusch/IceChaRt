seaIceRGB <- function(hh_path, hv_path,
                        input_in_db   = FALSE,
                        nodata        = NULL,
                        nodata_tol    = 1e-3, # tolerance for float
                        output_path   = NULL,
                        output_format = c("gtiff", "png"),
                        plot          = TRUE) {

  output_format <- match.arg(output_format)

  r_hh <- terra::rast(hh_path)
  r_hv <- terra::rast(hv_path)

# Handle NoData values
  nodata_hh <- if (!is.null(nodata)) nodata else terra::NAflag(r_hh)
  nodata_hv <- if (!is.null(nodata)) nodata else terra::NAflag(r_hv)

  message("NoData HH: ", nodata_hh)
  message("NoData HV: ", nodata_hv)

  if (!is.null(nodata_hh) && !is.nan(nodata_hh)) {
    r_hh <- terra::classify(r_hh,
                            rcl = matrix(c(nodata_hh - nodata_tol,
                                           nodata_hh + nodata_tol,
                                           NA),
                                         nrow = 1),
                            include.lowest = TRUE)
  }

  if (!is.null(nodata_hv) && !is.nan(nodata_hv)) {
    r_hv <- terra::classify(r_hv,
                            rcl = matrix(c(nodata_hv - nodata_tol,
                                           nodata_hv + nodata_tol,
                                           NA),
                                         nrow = 1),
                            include.lowest = TRUE)
  }

  stretch_r    <- function(r, vmin, vmax) terra::clamp((r - vmin) / (vmax - vmin), 0, 1)
  gamma_corr_r <- function(r, gamma = 1.1) terra::clamp(r, 0, 1)^(1 / gamma)

  mhv <- sqrt(r_hv + 0.002)
  mhh <- sqrt(r_hh + 0.002)
  ov  <- ((1 - 2 * mhh) * mhv + 2 * mhh) * mhv

  red   <- gamma_corr_r(stretch_r(mhv, 0.02, 0.10))
  green <- gamma_corr_r(stretch_r(ov,  0.00, 0.06))
  blue  <- gamma_corr_r(stretch_r(mhh, 0.00, 0.32))

  rgb <- c(red, green, blue)
  names(rgb) <- c("red", "green", "blue")

  if (plot) {
    terra::plotRGB(rgb * 255, r = 1, g = 2, b = 3, max = 255)
  }

  if (!is.null(output_path)) {
    if (output_format == "gtiff") {
      out_file <- paste0(tools::file_path_sans_ext(output_path), ".tif")
      terra::writeRaster(rgb, out_file, datatype = "FLT4S", overwrite = TRUE)
    } else {
      out_file <- paste0(tools::file_path_sans_ext(output_path), ".png")
      terra::writeRaster(rgb * 255, out_file, datatype = "INT1U",
                         filetype = "PNG", overwrite = TRUE)
    }
    message("RGB composite written to: ", out_file)
  }

  invisible(rgb)
}
