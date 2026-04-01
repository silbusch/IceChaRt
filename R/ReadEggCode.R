# !!!!NEED TO USE THIS: https://globalcryospherewatch.org/wordpress/wp-content/themes/global-cryosphere-watch/files/resources/JCOMM_TR23_SIGRID3.pdf

#INSTEAD OF THE OLD EGG CODE!!!!!

#  Internal helpers

.clean_value <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") {
    return("not available")
  }
  as.character(x)
}

.clean_numeric <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(x))
}

.translate_e_ca <- function(x) {
  x_num <- .clean_numeric(x)
  if (is.na(x_num)) return("not available")
  as.character(x_num * 10)
}

.translate_stage <- function(x) {
  x <- .clean_value(x)
  if (x %in% c("not available", "X")) return("not available")

  stage_map <- c(
    "1"    = "New ice (< 10 cm)",
    "2"    = "Nilas / Ice rind (< 10 cm)",
    "3"    = "Young ice (10-30 cm)",
    "4"    = "Grey ice (10-15 cm)",
    "5"    = "Grey-white ice (15-30 cm)",
    "6"    = "First-year ice (>= 30 cm)",
    "7"    = "Thin first-year ice (30-70 cm)",
    "8"    = "First stage thin first-year ice (30-50 cm)",
    "9"    = "Second stage thin first-year ice (50-70 cm)",
    "1."   = "Medium first-year ice (70-120 cm)",
    "4."   = "Thick first-year ice (> 120 cm)",
    "7."   = "Old ice",
    "8."   = "Second-year ice",
    "9."   = "Multi-year ice",
    "-9"   = "not available",
    "99"   = "not available",
    "null" = "not available"
  )

  if (x %in% names(stage_map)) stage_map[[x]] else as.character(x)
}

# Returns the first non-empty stage value from E_SO > E_SA > E_SB > E_SC > E_SD
.get_first_stage_value <- function(v) {
  for (col in c("E_SO", "E_SA", "E_SB", "E_SC", "E_SD")) {
    if (col %in% names(v)) {
      val <- .clean_value(v[[col]][1])
      if (!val %in% c("not available", "X")) return(val)
    }
  }
  "not available"
}

# Building Egg code Pairs for the consentration and development stage
# Also E_SO is a special case
# Column pairs: concentration column -> stage column
# E_SO is ice in traces (no concentration column), handled separately
.parse_ice_layers <- function(v) {
  pairs <- list(
    c(conc="E_CA", stage="E_SA"),
    c(conc="E_CB", stage="E_SB"),
    c(conc="E_CC", stage="E_SC"),
    c(conc="E_CD", stage="E_SD")
  )
  layers <- list()
  #special case for E_SO, because it indicates stage aber no concntration?:
  # To-Do: Need to check what SO means
  if ("E_SO"%in% names(v)) {
    so_val <- .clean_value(v[["E_SO"]][1])
    if (!so_val %in% c("not available", "X", "-9", "99", "null", "")){
      layers <- c(layers, list(list(
        conc_pct = NA_real_,
        stage = .translate_stage(so_val),
        is_trace=TRUE
      )))
    }
  }
  for (pair in pairs) {
    conc_col  <- pair["conc"]
    stage_col <- pair["stage"]

    conc_raw  <- if (conc_col  %in% names(v)) .clean_value(v[[conc_col]][1])  else "not available"
    stage_raw <- if (stage_col %in% names(v)) .clean_value(v[[stage_col]][1]) else "not available"

    conc_pct  <- .translate_concentration(conc_raw)
    stage_txt <- .translate_stage(stage_raw)

    # Only include the layer if at least one value is meaningful
    has_conc  <- !is.na(conc_pct)
    has_stage <- !stage_txt %in% "not available"

    if (has_conc || has_stage) {
      layers <- c(layers, list(list(
        conc_pct = conc_pct,
        stage    = stage_txt,
        is_trace = FALSE
      )))
    }
  }
  layers
}

# Returns a named list with all parsed polygon values (no formatting here)
.parse_polygon <- function(shp, polygon_id, id_col) {
  if (!inherits(shp, "SpatVector")) {
    stop("`shp` must be a terra::SpatVector.", call. = FALSE)
  }
  if (!(id_col %in% names(shp))) {
    stop(sprintf("ID column '%s' not found in `shp`.", id_col), call. = FALSE)
  }

  poly <- shp[shp[[id_col]] == polygon_id, ]

  if (nrow(poly) == 0) {
    stop(sprintf("No polygon with %s == %s found.", id_col, polygon_id), call. = FALSE)
  }

  v <- as.data.frame(poly)[1, , drop = FALSE]

  getv <- function(col) if (col %in% names(v)) .clean_value(v[[col]][1])  else "not available"
  getn <- function(col) if (col %in% names(v)) .clean_numeric(v[[col]][1]) else NA_real_

  # Resolve area — divide only if values suggest raw m² (> 1 000 000)
  area_raw <- getn("AREA")
  area_km2 <- if (!is.na(area_raw)) {
    if (area_raw > 1e6) area_raw / 1e6 else area_raw   # guard for already-km² data
  } else NA_real_

  list(
    polygon_label = getv(id_col),
    area_km2      = area_km2,
    ct            = getn("CT"),
    e_ca_pct      = .translate_e_ca(getv("E_CA")),
    stage         = .translate_stage(.get_first_stage_value(v))
  )
}


#' Looks up a single polygon by ID from a sea-ice shapefile (egg-code format) and
#' turn it into easy readable text
#'
#' @param shp      A \code{terra::SpatVector} loaded from an CIS shapefile.
#' @param polygon_id  The identifier of the unique polygon ID to describe.
#' @param id_col   Name of the column that holds polygon IDs
#' @param add_id   If \code{TRUE} (default), \code{\link{add_poly_id}} is called
#'                 automatically when \code{id_col} is missing from \code{shp}.
#'
#' @return A single character string with the polygon description.
#'
#'
#' @export
describe_ice_polygon <- function(shp, polygon_id, id_col = "poly_id", add_id = TRUE) {

  # Auto-add ID column if requested and missing
  if (add_id && !(id_col %in% names(shp))) {
    shp <- add_poly_id(shp, id_col)
  }

  p <- .parse_polygon(shp, polygon_id, id_col)

  area_txt <- if (!is.na(p$area_km2)) {
    format(round(p$area_km2, 2), nsmall = 2, big.mark = ",")
  } else {
    "not available"
  }

  ct_txt <- if (!is.na(p$ct)) as.character(p$ct) else "not available"

  stage_txt <- if (!p$e_ca_pct %in% "not available" && !p$stage %in% "not available") {
    paste0(p$e_ca_pct, "% in the stage of ", p$stage)
  } else {
    "not available"
  }

  # One sentence per layer
  if (length(p$ice_layers) == 0) {
    layers_txt <- "  - not available"
  } else {
    layer_lines <- vapply(p$ice_layers, function(layer) {
      if (isTRUE(layer$is_trace)) {
        paste0("  - Traces: ", layer$stage)
      } else {
        conc_str  <- if (!is.na(layer$conc_pct)) paste0(layer$conc_pct, "%") else "unknown concentration"
        stage_str <- if (!layer$stage %in% "not available") layer$stage else "unknown stage"
        paste0("  - ", conc_str, ": ", stage_str)
      }
    }, character(1))
    layers_txt <- paste(layer_lines, collapse = "\n")
  }
  paste0(
    "Polygon ", p$polygon_label, " covers ", area_txt, " km\u00b2. ",
    ct_txt, "% of this area is ice-covered, ",
    "with the following stage distribution:\n", layers_txt
  )
}
