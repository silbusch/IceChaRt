# Sea-Ice Polygon Description Utilities  (SIGRID-3 / CIS egg-code format)
# Reference: https://download.dmi.dk/public/ICESERVICE/2024_download_readme/ETSI6-Doc-3%201%202-SIGRID-3_1_App_A_SIGRID3_rev3-1_v5.pdf


#--- Lookup tables -------------------------------------------------------------
codes <- c(
  "AREA"="Area of polygon feature",
  "PERIMETER" = "Perimeter length of polygon feature",
  "POLY_TYPE" = "Type of polygon feature",
  "CT" = "Total concentration",
  "CA" = "Partial concentration of thickest ice",
  "CB" = "Partial concentration of second thickest ice",
  "CC" = "Partial concentration of the third thickest ice",
  "CN" = "Stage of development of ice thicker than SA but with concentration less then 1/10",
  "SA" = "Stage of development of thickest ice",
  "SB" = "Stage of development of second thickest Ice",
  "SC" = "Stage of development of third thickest ice",
  "CD" = "Stage of development of any remaining class of ice",
  "FA" = "Form of thickest ice",
  "FB" = "Form of second thickest ice",
  "FC" = "Form of third thickest ice",
  "FP" = "Predominant form of ice",
  "FS" = "Secondary form of ice",
  "CF" = "Predominant and secondary forms of ice"
)

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
  "92"= "10/10",
  "-9"= "Not set"
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
  "99"= "Unknown",
  "-9"= "Not set"
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
  "-9"= "Not set"
)

# Form of ice codes for variable identifiers FA, FB, FC, FP and FS.
ice_form <- c(
  "01"= "Pancake Ice (30 cm - 3 m)",
  "02" = "Shuga/Small Ice Cake, Brash Ice (< 2 m across)",
  "03" = "Ice Cake (< 20 m across)",
  "04" = "Small Floe (20 m - 100 m across)",
  "05" = "Medium Floe (100 m - 500 m across)",
  "06" = "Big Floe (500 m - 2 km across)",
  "07" = "Vast Floe (2 km - 10 km across)",
  "08" = "Giant Floe (> 10 km across)",
  "09" = "Fast Ice",
  "10" = "Growlers, Floebergs or Floebiits",
  #"10"= "Icebergs",
  "11"= "Strips and Patches concentrations 1/10",
  "12"= "Strips and Patches concentrations 2/10",
  "13"= "Strips and Patches concentrations 3/10",
  "14"="Strips and Patches concentrations 4/10",
  "15"="Strips and Patches concentrations 5/10",
  "16"="Strips and Patches concentrations 6/10",
  "17"="Strips and Patches concentrations 7/10",
  "18"="Strips and Patches concentrations 8/10",
  "19"="Strips and Patches concentrations 9/10",
  "91"="Strips and Patches concentrations 9+/10",
  "20"="Strips and Patches concentrations 10/10",
  #"21"= "Level Ice",
  "99"= "undetermined/Unknown",
  "-9"= "Not set"
)

#List of Poly_type character variables
poly_type <- c(
  "L" = "Land",
  "W"= "Water (sea ice free)",
  "I" = "Ice – of any concentration",
  "N" = "No Data",
  "S" = "Ice Shelf / Ice of Land Origin",
  "-9"= "Not set"
)

#  Internal helpers
#--- Handling No Data ----------------------------------------------------------

.NOT_SET <- c("-9", "Not set", "")

.clean_value <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") return(NA_character_)
  trimws(as.character(x))
}

.clean_numeric <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") return(NA_real_)
  suppressWarnings(as.numeric(x))
}

#---Reading SIGRID3 code -------------------------------------------------------

# SIGRID3 Code as string for ice concentration
.translate_concentration <- function(x) {
  x <- .clean_value(x)
  if (is.na(x) || x %in% .NOT_SET) return(NA_character_)
  if (x %in% names(ice_concentration)) {
    val <- ice_concentration[[x]]
    return(if (val %in% .NOT_SET) NA_character_ else val)
  }
  if (x %in% names(ice_concentration_intervals)) {
    val <- ice_concentration_intervals[[x]]
    return(if (val %in% .NOT_SET) NA_character_ else val)
  }
  NA_character_
}

# SIGRID3 Code as string for stage of development
# return raw code if not in table (so nothing is lost)
.translate_stage <- function(x) {
  x <- .clean_value(x)
  if (is.na(x) || x %in% .NOT_SET) return(NA_character_)
  if (x %in% names(ice_stage_development)) {
    val <- ice_stage_development[[x]]
    return(if (val %in% .NOT_SET) NA_character_ else val)
  }
  x  # return raw code if not in table so nothing lost
}

# SIGRID3 Code as string for ice form
.translate_form <- function(x) {
  x <- .clean_value(x)
  if (is.na(x) || x %in% .NOT_SET) return(NA_character_)
  if (x %in% names(ice_form)) {
    val <- ice_form[[x]]
    return(if (val %in% .NOT_SET) NA_character_ else val)
  }
  x  # raw code as fallback
}

#To-Do: ?????CF ist 4-Zeichen-String: ersten zwei Zeichen = FP, letzten 2 = FS????? In Doc schauen
.translate_cf <- function(x) {
  x <- .clean_value(x)
  if (is.na(x) || x %in% .NOT_SET) return(NA_character_)
  if (nchar(x) == 4) {
    fp_txt <- .translate_form(substr(x, 1, 2))
    fs_txt <- .translate_form(substr(x, 3, 4))
    parts  <- c(
      if (!is.na(fp_txt)) paste0("predominant: ", fp_txt),
      if (!is.na(fs_txt)) paste0("secondary: ",   fs_txt)
    )
    if (length(parts) == 0) return(NA_character_)
    return(paste(parts, collapse = ", "))
  }
  .translate_form(x)
}

#---Ice layer intrepretation -------------------------------------------------------

# Returns a list of layers, each a named list with: conc, stage, form, is_minor
# is_minor = TRUE  for CN / CD layers (concentration implicitly < 1/10,no concentration column exists)
# is_minor = FALSE for the regular CA/CB/CC layers
.parse_ice_layers <- function(v) {

  getraw <- function(col) {
    if (col %in% names(v)) .clean_value(v[[col]][1]) else NA_character_
  }

  layers <- list()

  # Regular layers combination: CA/SA/FA, CB/SB/FB, CC/SC/FC
  triplets <- list(
    c(conc = "CA", stage = "SA", form = "FA"),
    c(conc = "CB", stage = "SB", form = "FB"),
    c(conc = "CC", stage = "SC", form = "FC")
  )

  for (tri in triplets) {
    conc_txt  <- .translate_concentration(getraw(tri["conc"]))
    stage_txt <- .translate_stage(getraw(tri["stage"]))
    form_txt  <- .translate_form(getraw(tri["form"]))

    # Skip if nothing meaningful in this column
    if (is.na(conc_txt) && is.na(stage_txt) && is.na(form_txt)) next
    layers <- c(layers, list(list(
      conc     = conc_txt,
      stage    = stage_txt,
      form     = form_txt,
      is_minor = FALSE
    )))
  }

  #minor layers: CN and CD (concentration < 1/10, stage only)
  # CF is the polygon-wide predominant/secondary form --> stored separately.
  for (col in c("CN", "CD")) {
    stage_txt <- .translate_stage(getraw(col))
    if (!is.na(stage_txt)) {
      layers <- c(layers, list(list(
        conc     = NA_character_,
        stage    = stage_txt,
        form     = NA_character_,
        is_minor = TRUE
      )))
    }
  }

  layers
}

# Return list of all values
.parse_polygon <- function(shp, polygon_id, id_col) {
  if (!inherits(shp, "SpatVector"))
    stop("`shp` must be a terra::SpatVector.", call. = FALSE)
  if (!(id_col %in% names(shp)))
    stop(sprintf("ID column '%s' not found in `shp`.", id_col), call. = FALSE)

  poly <- shp[as.character(shp[[id_col]]) == as.character(polygon_id), ]
  if (nrow(poly) == 0)
    stop(sprintf("No polygon with %s == %s found.", id_col, polygon_id),
         call. = FALSE)

  v <- as.data.frame(poly)[1, , drop = FALSE]

  getv <- function(col)
    if (col %in% names(v)) .clean_value(v[[col]][1]) else NA_character_
  getn <- function(col)
    if (col %in% names(v)) .clean_numeric(v[[col]][1]) else NA_real_

  # Convert area from m² to km²
  area_raw <- getn("AREA")
  area_km2 <- if (!is.na(area_raw)) area_raw / 1e6 else NA_real_

  list(
    polygon_label = as.character(polygon_id),
    area_km2      = area_km2,
    ct            = .translate_concentration(getv("CT")),
    cf            = .translate_cf(getv("CF")),
    ice_layers    = .parse_ice_layers(v)
  )
}

#' Describe a sea-ice polygon based on SIGRID3 code
#'
#' Looks up one polygon by ID from a shapefile in SIGRID3-code and returns a
#' description of its ice conditions, including concentration,
#' stage of development, and ice form for each polygon.
#'
#' Non-ice polygons (Land, Water, No Data, Ice Shelf) are reported with a
#' short one-line message instead.
#'
#' @param shp        A \code{terra::SpatVector} loaded from a CIS ice chart shapefile.
#' @param polygon_id A single ID or vector of IDs identifying the target polygon(s).
#' @param id_col     Name of the column holding polygon IDs (default: \code{"ID_NEW"}).
#' @param save_txt   Logical. If \code{TRUE}, output is saved as a .txt file.
#' @param file_path  Optional path for the output file. Auto-generated if \code{NULL}.
#'
#' @return Invisibly returns the description string; output is printed via \code{cat()}.
#' @export
ReadSIGRID3 <- function(shp,
                        polygon_id,
                        id_col = "ID_NEW",
                        save_txt = TRUE,
                        file_path = NULL) {

  .describe_one <- function(pid) {

    poly <- shp[as.character(shp[[id_col]]) == as.character(pid), ]
    if (nrow(poly) == 0)
      stop(sprintf("No polygon with %s == %s found.", id_col, pid), call. = FALSE)

    v <- as.data.frame(poly)[1, , drop = FALSE]

    # Early exit for non-ice polygons (Land, Water, No Data, Ice Shelf)
    if ("POLY_TYPE" %in% names(v)) {
      pt_code <- .clean_value(v[["POLY_TYPE"]][1])
      if (!is.na(pt_code) && pt_code != "I") {
        label <- if (pt_code %in% names(poly_type)) poly_type[[pt_code]] else pt_code
        return(paste0("Polygon ", pid, " only contains: ", label, "."))
      }
    }

  #---------------------------------------------------------------------------
    p <- .parse_polygon(shp, pid, id_col)

    # area
    area_txt <- if (!is.na(p$area_km2)) {
      format(round(p$area_km2, 2), nsmall = 2, big.mark = ",")
    } else "not available"

    # total sea ice concentration for the polygon
    ct_txt <- if (!is.na(p$ct)) p$ct else "not available"

    # Ice  development, form text
    if (length(p$ice_layers) == 0) {
      layers_txt <- "  - No partial concentration data available"
    } else {
      layer_lines <- vapply(p$ice_layers, function(layer) {
        if (isTRUE(layer$is_minor)) {
          stage_str <- if (!is.na(layer$stage)) layer$stage else "unknown stage"
          paste0("  - < 1/10: ", stage_str)
        } else {
          conc_str  <- if (!is.na(layer$conc))  layer$conc  else "unknown concentration"
          stage_str <- if (!is.na(layer$stage)) layer$stage else "unknown stage"
          line <- paste0(conc_str, " in the stage of ", stage_str)
          if (!is.na(layer$form)) line <- paste0(line, " in the form of ", layer$form)
          paste0("  - ", line)
        }
      }, character(1))
      layers_txt <- paste(layer_lines, collapse = "\n")
    }

    cf_line <- if (!is.na(p$cf)) paste0("\n  Predominant/secondary form: ", p$cf) else ""


    paste0(
      "Polygon ", p$polygon_label, " covers ", area_txt, " km\u00b2.\n",
      ct_txt, " of this area is ice-covered, ",
      "with the following stage distribution:\n",
      layers_txt,
      cf_line
    )
  }

  #-Describe polygons --------------------------------------------------------------------------
  descriptions <- vapply(polygon_id, .describe_one, character(1))
  cat(paste(descriptions, collapse = "\n\n"), "\n\n")

# --- Optional: save as .txt-----------------------------------------
  if (save_txt) {
    if (is.null(file_path)) {
      main_dir  <- file.path(getwd(), "IceChaRt_output")
      out_dir   <- file.path(main_dir, "SIGRID3_text")
      for (d in c(main_dir, out_dir)) {
        if (!dir.exists(d)) {
          dir.create(d, recursive = TRUE)
          message("Created directory: ", d)
        }
      }
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      file_path <- file.path(out_dir, paste0("IceChaRt_SIGRID3_", timestamp, ".txt"))
    } else {
      out_dir <- dirname(file_path)
      if (!dir.exists(out_dir)) {
        dir.create(out_dir, recursive = TRUE)
        message("Created output directory: ", out_dir)
      }
      if (!grepl("\\.txt$", file_path, ignore.case = TRUE)) {
        file_path <- paste0(file_path, ".txt")
      }
    }

    header <- paste0(
      "IceChaRt - Sea Ice Polygon Description\n",
      "Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
      "Polygons:  ", paste(polygon_id, collapse = ", "), "\n",
      strrep("-", 50), "\n\n"
    )

    writeLines(paste0(header, paste(descriptions, collapse = "\n\n")), file_path)
    message("Output saved to: ", file_path)
  }

  invisible(descriptions)
}
