# Sea-Ice Polygon Description Utilities  (SIGRID-3 / CIS egg-code format)
# Reference: https://globalcryospherewatch.org/wordpress/wp-content/themes/
#            global-cryosphere-watch/files/resources/JCOMM_TR23_SIGRID3.pdf

# CT = Total concentration
# CA = Partial concentration of thickest ice
# SA = Stage of development of thickest ice
# FA = Form of thickest ice
# CB = Partial concentration of second thickest ice
# SB = Stage of development of second thickest Ice
# FB = Form of second thickest ice
# CC = Partial concentration of the third thickest ice
# SC = Stage of development of third thickest ice
# FC = Form of third thickest ice
# CN = Stage of development of ice thicker than SA but with concentration less then 1/10
# CD =Stage of development of any remaining class of ice
# CF = Predominant and secondary forms of ice

# Lookup tables
# Concentration codes for variable identifiers CT, CA, CB, and CC.
ice_concentration <- c(
  "00" = "Ice Free",
  "01"= "Less than 1/10 of ice (open water)",
  "02" = "Bergy Water",
  "10" = "1/10",
  "20" = "2/10",
  "30" = "3/10",
  "40" = "4/10",
  "50" = "5/10",
  "60" = "6/10",
  "70" = "7/10",
  "80" = "8/10",
  "90" = "9/10",
  "92"= "10/10"
)

#Concentration intervals (lowest concentration in interval followed by highest
ice_concentration_intervals <- c(
  "91" = "9/10 –10/10",
  "89"= "8/10 – 9/10",
  "81" = "8/10 – 10/10",
  "79" = "7/10 – 9/10",
  "78" = "7/10 – 8 /10",
  "68" = "6/10 – 8/10",
  "67" = "6/10 – 7/10",
  "57" = "5/10 – 7/10",
  "56" = "5/10 – 6/10",
  "46" = "4/10 – 6/10",
  "45" = "4/10 – 5/10",
  "35" = "3/10 – 5/10",
  "34" = "3/10 – 4/10",
  "24" = "2/10 – 4/10",
  "23"= "2/10 – 3/10",
  "13"= "1/10 – 3/10",
  "12"= "1/10 – 2/10",
  "99"= "Unknown"
)

# Thickness of ice or stage of development codes for variable identifiers
# SA, SB, SC, CN,and CD.
ice_stage_development <- c(
  "0" = "Ice Free",
  "80"= "No Stage of Development",
  "81" = "New ice",
  "82" = "Nilas / Ice rind (< 10 cm thickness)",
  "83" = "Young ice (10-30 cm thickness)",
  "84" = "Grey ice (10-15 cm thickness)",
  "85" = "Grey-white ice (15-30 cm thickness)",
  "86" = "First-year ice (30 - 200 cm thickness)",
  "87" = "Thin First Year Ice (30-70 cm thickness)",
  "88" = "Thin First Year Ice Stage 1 (30-50 cm thickness)",
  "89" = "Thin First Year Ice Stage 2 (50-70 cm thickness)",
  "90"= "Not set", #For later use
  "91"= "Medium First Year Ice (70-120 cm thickness)",
  "92"= "Not set", #For later use
  "93"= "Thick First Year Ice (> 120 cm thickness)",
  "94"="Not set", #For later use
  "95"= "Old ice",
  "96"= "Second Year Ice",
  "97"= "Multi Year Ice",
  "98"= "Glacier Ice",
  "99"= "undetermined/Unknown",
  "null" = "not available"
)

# Form of ice codes for variable identifiers FA, FB, FC, and CF.
ice_form <- c(
  "00"= "Pancake Ice (30 cm - 3 m)",
  "01" = "Shuga/Small Ice Cake, Brash Ice (< 2 m across)",
  "02" = "Ice Cake (< 20 m across)",
  "03" = "Small Floe (20 m - 100 m across)",
  "04" = "Medium Floe (100 m - 500 m across)",
  "05" = "Big Floe (500 m - 2 km across)",
  "06" = "Vast Floe (2 km - 10 km across)",
  "07" = "Giant Floe (> 10 km across)",
  "08" = "Fast Ice",
  "09" = "Growlers, Floebergs or Floebiits",
  "10"= "Icebergs",
  "11"= "Strips and Patches concentrations 1/10",
  "12"= "Strips and Patches concentrations 2/10",
  "13"= "Strips and Patches concentrations 3/10",
  "14"="Strips and Patches concentrations 4/10",
  "15"="Strips and Patches concentrations 5/10",
  "16"="Strips and Patches concentrations 6/10",
  "17"="Strips and Patches concentrations 7/10",
  "18"="Strips and Patches concentrations 8/10",
  "19"="Strips and Patches concentrations 9/10",
  "20"="Strips and Patches concentrations 10/10",
  "21"= "Level Ice",
  "99"= "undetermined/Unknown",
  "null" = "not available"
)

#List of Poly_type character variables
poly_type <- c(
  "L" = "Land",
  "W"= "Water – sea ice free",
  "I" = "Ice – of any concentration",
  "N" = "No Data",
  "S" = "Ice Shelf / Ice of Land Origin"
)

#  Internal helpers
#--- Handling No Data ----------------------------------------------------------

.clean_value <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") {
    return(NA_character_)
  }
  as.character(x)
}

.clean_numeric <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(x))
}

#---Reading SIGRID3 code -------------------------------------------------------

# SIGRID3 Code as string for ice concentration
.translate_concentration <- function(x) {
  x <- .clean_value(x)
  if (is.na(x)) return(NA_character_)
  if (x %in% names(ice_concentration))
    return(ice_concentration[[x]])
  if (x %in% names(ice_concentration_intervals))
    return(ice_concentration_intervals[[x]])
  NA_character_
}

# SIGRID3 Code as string for stage of development
# return raw code if not in table (so nothing is lost)
.translate_stage <- function(x) {
  x <- .clean_value(x)
  if (is.na(x)) return(NA_character_)
  if (x %in% names(ice_stage_development))
    return(ice_stage_development[[x]])
  x
}

# SIGRID3 Code as string for ice form
.translate_form <- function(x) {
  x <- .clean_value(x)
  if (is.na(x)) return(NA_character_)
  if (x %in% names(ice_form)) return(ice_form[[x]])
  x  # return raw code if not in table
}

.translate_e_ca <- function(x) {
  x_num <- .clean_numeric(x)
  if (is.na(x_num)) return("not available")
  as.character(x_num * 10)
}

#---------------------------------------------------------------






# Building Egg code Pairs for the consentration and development stage
# Also E_SO is a special case
# Column pairs: concentration column -> stage column
# E_SO is ice in traces (no concentration column), handled separately
.parse_ice_layers <- function(v) {
  pairs <- list(
    c(conc="CA", stage="SA", stage="FA"),
    c(conc="CB", stage="SB", stage="FB"),
    c(conc="CC", stage="SC", stage="FC"),
    c()
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
