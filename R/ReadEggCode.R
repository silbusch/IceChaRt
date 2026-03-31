library(terra)

.clean_value <- function(x) {
  if (length(x) == 0 || is.na(x) || x == "" || is.null(x)) {
    return("not available")
  }
  as.character(x)
}

# read in numerical values stable!!!!!!
.clean_numeric <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x) || x == "") {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(x))
}

# create poly_iDs if they dont have one yet
add_poly_id <- function(shp, id_col = "poly_id") {
  if (!inherits(shp, "SpatVector")) {
    stop("'shp' hast to be a terra::SpatVector.", call. = FALSE)
  }

  if ("POLY_TYPE" %in% names(shp)) {
    shp <- shp[is.na(shp$POLY_TYPE) | shp$POLY_TYPE != "L", ]
  }

  if (!(id_col %in% names(shp))) {
    shp[[id_col]] <- seq_len(nrow(shp))
  }

  shp
}

# Retrieve a single polygon as a data row
.get_polygon_row <- function(shp, polygon_id, id_col = "poly_id") {
  if (!inherits(shp, "SpatVector")) {
    stop("'shp' hast to be a terra::SpatVector.", call. = FALSE)
  }

  if (!(id_col %in% names(shp))) {
    stop(paste0("Die ID column ", id_col, " does not exist"), call. = FALSE)
  }

  poly <- shp[shp[[id_col]] == polygon_id, ]

  if (nrow(poly) == 0) {
    stop("No polygon with this ID was found.", call. = FALSE)
  }

  vals <- as.data.frame(poly)
  vals[1, , drop = FALSE]
}

# transform E_CA in %
.translate_e_ca <- function(x) {
  x_num <- .clean_numeric(x)

  if (is.na(x_num)) {
    return("not available")
  }

  # 8 -> 80, 10 -> 100
  as.character(x_num * 10)
}

#Translate stage code into text
.translate_stage <- function(x) {
  x <- .clean_value(x)

  if (x == "not available" || x == "X") {
    return("not available")
  }

  map <- c(
    "1"  = "New ice with < 10 centimetres thickness",
    "2"  = "Nilas / Ice rind with < 10 centimetres thickness",
    "3"  = "Young ice with 10 - 30 centimetres thickness",
    "4"  = "Grey ice with 10 - 15 centimetres thickness",
    "5"  = "Grey-white ice with 15 - 30 centimetres thickness",
    "6"  = "First-year ice with >= 30 centimetres thickness",
    "7"  = "Thin first-year ice with 30 - 70 centimetres thickness",
    "8"  = "First stage thin first-year ice with 30 - 50 centimetres thickness",
    "9"  = "Second stage thin first-year ice with 50 - 70 centimetres thickness",
    "1." = "Medium first-year ice with 70 - 120 centimetres thickness",
    "4." = "Thick first-year ice with > 120 centimetres thickness",
    "7." = "Old ice",
    "8." = "Second-year ice",
    "9." = "Multi-year ice",
    "-9" = "empty",
    "99" = "undetermined or unknown",
    "null" = "undetermined or unknown"
  )

  if (x %in% names(map)) {
    return(map[[x]])
  }

  as.character(x)
}

# SO -> SA -> SB -> SC -> SD
.get_first_stage_value <- function(v) {
  stage_cols <- c("E_SO", "E_SA", "E_SB", "E_SC", "E_SD")

  for (col in stage_cols) {
    if (col %in% names(v)) {
      value <- .clean_value(v[[col]][1])

      if (!is.na(value) && value != "" && value != "not available" && value != "X") {
        return(value)
      }
    }
  }

  return("not available")
}

# Sentence component for "[...] % in the stage of [...]"
describe_stage_distribution <- function(shp, polygon_id, id_col = "poly_id") {
  v <- .get_polygon_row(shp, polygon_id, id_col)

  e_ca_raw <- if ("E_CA" %in% names(v)) v[["E_CA"]][1] else NA
  e_txt <- .translate_e_ca(e_ca_raw)

  stage_raw <- .get_first_stage_value(v)
  f_txt <- .translate_stage(stage_raw)

  if (e_txt == "not available" || f_txt == "not available") {
    return("- The corresponding stage distribution is not available.")
  }

  paste0(e_txt, "% in the stage of ", f_txt)
}

# Create first sentence
describe_polygon_intro <- function(shp, polygon_id, id_col = "poly_id") {
  v <- .get_polygon_row(shp, polygon_id, id_col)

  getv <- function(col) {
    if (col %in% names(v)) .clean_value(v[[col]][1]) else "not available"
  }

  getn <- function(col) {
    if (col %in% names(v)) .clean_numeric(v[[col]][1]) else NA_real_
  }

  polygon_label <- getv(id_col)
# To-Do: Not sure if really square meters or already square kilometers
  area_m2 <- getn("AREA")
  area_km2 <- if (!is.na(area_m2)) area_m2 / 1e6 else NA_real_

  area_txt <- if (!is.na(area_km2)) {
    format(round(area_km2, 2), nsmall = 2, decimal.mark = ",")
  } else {
    "not available"
  }

  ct_value <- getn("CT")

  ct_txt <- if (!is.na(ct_value)) {
    as.character(ct_value)
  } else {
    "not available"
  }

  stage_txt <- describe_stage_distribution(shp, polygon_id, id_col)

  paste0(
    "The Polygon ", polygon_label,
    " has a total area of ", area_txt, " km². ",
    "Of this ", ct_txt, "% is covered by ice, with the following distributions: ",
    stage_txt, "."
  )
}

shp <- vect("C:/Users/Duck/Documents/Studium/EAGLE/03_semester/5_r_package/TestData/02112020_CEXPREA.shp")

shp <- add_poly_id(shp)
describe_polygon_intro(shp, polygon_id = 16, id_col = "poly_id")

