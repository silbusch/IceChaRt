#' Download example raster data for IceChaRt
#'
#' Downloads bigger test data for the IceChaRt package to try out all functions.
#' Only needs to be run once.
#'
#' @param dest Directory where the files should be saved.
#'   Defaults to the \code{extdata} folder of the installed IceChaRt package.
#'
#' @return Invisibly returns the path where files were saved.
#'
#' @examples
#' \dontrun{
#' download_testdata_IceChaRt()
#'
#' # Directly usable:
#' co_pol    <- terra::rast(system.file("extdata", "s1_20201101_hh.tif", package = "IceChaRt"))
#' cross_pol <- terra::rast(system.file("extdata", "s1_20201101_hv.tif", package = "IceChaRt"))
#'
#' }
#'
#' @export

download_testdata_IceChaRt <- function(dest = system.file("extdata", package = "IceChaRt")) {

  if (!requireNamespace("piggyback", quietly = TRUE)) {
    stop("Bitte zuerst installieren: install.packages('piggyback')")
  }

  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  message("Downloading example data to: ", dest)

  piggyback::pb_download(
    repo = "silbusch/IceChaRt",
    tag  = "v0.1-data",
    dest = dest
  )

  message("Data saved to: ", dest)
  invisible(dest)
}
