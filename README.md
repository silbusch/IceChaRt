# IceChaRt
An R package to help you get started with the topic of sea ice.

**IceChaRt** allows users to search for and download sea ice charts, retrieve standardized vector data in the _Sea Ice GeoReferenced Information and Data_ (SIGRID-3) format, and extract egg code information for sea ice classification [[1](#source1), [2](#source2)]. **IceChaRt** also provides a function for colourising Sentinel-1 EW/IW dual-polarisation SAR images into RGB GeoTIFFs following the sea-ice composite by _Martin Raspaud_ and _Mikhail Itkin_, where co-polarisation (HH or VV) and cross-polarisation (HV or VH) are combined to emphasise different stages of sea-ice development [[3](#source3)].

![EggCode](https://github.com/user-attachments/assets/d2147f3a-56b7-46c2-b228-464724da1461 "EggCode")

Figure 1: The Egg Code used for SIGRID-3 [[2](#source2)]

---

## Regions
Ice charts are available for download for the following regions:

|  |
| :------------------- |
|<img width="669" height="425" alt="image" src="https://github.com/user-attachments/assets/2a1801ff-01cd-4c39-bbbb-50d1ca3954bd" />|
|Figure 2: Ice chart regions of the Danish Meteorological Institute (DMI) [[4](#source4)].|
|<img width="594" height="471" alt="image" src="https://github.com/user-attachments/assets/79d39a9f-92cf-4798-8711-7bae3c489f90" />|
|Figure 3: Ice chart regions of the Canadian Ice Service (CIS) [[5](#source5)].|
|<img width="1650" height="1275" alt="sod_ant_20260403" src="https://github.com/user-attachments/assets/161143d0-e9f8-4510-84dd-4032f669fe02" />|
|Figure 4: Antarctic example ice chart region of the U.S. National Ice Center (NIC) [[6](#source6)].|
|<img width="1650" height="1275" alt="sod_arc_20260409" src="https://github.com/user-attachments/assets/aa6bbd1e-2156-40c0-bcad-f6e14483fae2" />|
|Figure 5: Arctic example ice chart region of the U.S. National Ice Center (NIC) [[6](#source6)].|
---

# Package Functions

| Function             | Description  |Output |
| :------------------- | :---------- | :---------- |
| `search_icechart()`  | Searches for weekly ice charts from the CIS, NIC or DMI for a given region and year.| A list of matching ice charts printed to the user's console. |
| `download_icechart()`| Downloads an ice chart, adds a new ID column, and saves it as an `sf` object. |An `sf` object containing ice chart polygons and unique IDs.|
| `seaice_studyarea()`     | Clips an ice-chart `SpatVector` to the extent of a `SpatRaster`, with optional reprojection and land masking.| A cropped `SpatVector` and a land-masked, reprojected `SpatRaster`. |
| `read_sigrid3()`        | Interprets the SIGRID3 code for a sea-ice polygon. | A text file containing the polygon description.|
| `s1_seaice_rgb()`       | Creates a false-color sea-ice RGB composite from Sentinel-1 dual-polarization SAR data.| An RGB `SpatRaster`. |
| `download_testdata_IceChaRt`| Downloads bigger test data for the IceChaRt package.| `SpatRaster` |
---
---

# Example Workflow

## Install Package
```r
install.packages("remotes")
library(remotes)

remotes::install_github("silbusch/IceChaRt")
library(IceChaRt)
```
---

## Search Ice Chart: `search_icechart()`
```r
# Search for an ice chart from the Canadian Ice Service (CIS),  U.S. National Ice Center (NIC) or
# Danish Meteorological Institute (DMI).

# To find out which regions are available run:
?search_icechart()

# Example CIS
IceChaRt::search_icechart(institution= "CIS", region="Eastern_Arctic", year="2020")
```
*Console output:*
```
                  filename                            url                                                                                                 date          version
1                 cis_SGRDREA_20191230T1800Z_pl_a.tar https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20191230T1800Z_pl_a.tar 2019-12-30       a
2                 cis_SGRDREA_20200106T1800Z_pl_a.tar https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20200106T1800Z_pl_a.tar 2020-01-06       a
3                 cis_SGRDREA_20200113T1800Z_pl_a.tar https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20200113T1800Z_pl_a.tar 2020-01-13       a
[...]
57                cis_SGRDREA_20201228T1800Z_pl_a.tar https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20201228T1800Z_pl_a.tar 2020-12-28       a
```
---

## Download Ice Chart: `download_icechart()`
```r
# If you do not specify a destination folder, the IceChaRt_output folder will
# be created in your working directory. You can download a single chart,
# a period containing several charts, or an entire year of charts for a specific region.

?download_icechart()

# The "ID_NEW" column is always created, as not all charts have unique polygon IDs.
# Alls Charts will be converted to .gpkg

# Example: Download one specific chart:
IceChaRt::download_icechart(institution= "CIS", region = "Eastern_Arctic", date = "2020-11-02")

v = terra::vect("IceChaRt_output/ice_charts/CIS_cis_SGRDREA_20201102T1800Z_pl_a.gpkg")

# Plot overall ice concentration:
terra::plot(v, "CT", main="Sea ice concentration| CT-Code")
# Plot form of ice:
terra::plot(v, "FA", main="Form of ice| FA-Code")
```
*Console output:*
```
No encoding supplied: defaulting to UTF-8.
Downloading (1/1): cis_SGRDREA_20201102T1800Z_pl_a.tar
  |====================================================================================================================| 100%
  Converting to .gpkg: CIS_cis_SGRDREA_20201102T1800Z_pl_a.gpkg
Files saved to: C:/Users/.../IceChaRt_output/ice_charts
```
|     |  |
| :------------------- | :---------- |
|  ![CT](https://github.com/user-attachments/assets/dfa39cd8-bca9-4a3b-a6b0-8d731f770f98)|![FA](https://github.com/user-attachments/assets/3ee998c9-175a-4128-b8ed-5077ed29381f)|

---

## Read SIGRID-3 code: `read_sigrid3()`

The georeferenced version of the following ice chart has been downloaded. In the following, the SIGRID-3 table of EggCodes for the polygons JJ (ID: 309), EE (ID: 310), GG (ID: 311), Land (ID: 312), and X (ID: 313) is read using the function and converted into understandable text. 

![sc_a11_20201102_WIS55](https://github.com/user-attachments/assets/553cb516-f399-4cb9-8b9e-7a67ca97a365)

Figure 6: Regional Ice Analysis eastern Artic, week of the 02. NOV 2020 [[7](#source7)]

```r
# Get the interpretation of SIGRID-3 code for sea ice data from each polygon 
# without needing to know it or understand the Egg Code/ SIGRID-3.

?read_sigrid3()

# Check the sea ice conditions for the polygons you’re interested in:
as.data.frame(v)[309:313, ]
IceChaRt::read_sigrid3(v, polygon_id = c(309:313), save_txt = TRUE)

#By default, the text displayed in the console is also saved as a .txt file in IceChaRt_output/SIGRID3_text. 
```
*Console output:*
```
> as.data.frame(v)[309:313, ]
           AREA  PERIMETER   CT   CA   SA   FA   CB   SB   FB   CC   SC   FC   CN   CD   CF POLY_TYPE ID_NEW
309  2446363224  447242.55   91   10   85   05   60   84   04   30   81   99   -9   -9 0499         I    309
310  4547432801  695990.31   91   30   97   06   20   96   06   50   87   05   -9   -9 0506         I    310
311  1419996891  173514.33   91   20   85   05   40   84   04   40   81   99   97   -9 0499         I    311
312    68138602   76110.37 <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA>         L    312
313 13193648654 1191318.05   91   60   85   05   30   84   04   10   81   99   97   -9 0504         I    313


> IceChaRt::read_sigrid3(v, polygon_id = c(309:313), save_txt = TRUE)
Polygon 309 covers 2,446.36 km².
9/10 - 10/10 of this area is ice-covered, with the following stage distribution:
  - 1/10 in the stage of Grey-white ice (15-30 cm thickness) in the form of Medium Floe (100 m - 500 m across)
  - 6/10 in the stage of Grey ice (10-15 cm thickness) in the form of Small Floe (20 m - 100 m across)
  - 3/10 in the stage of New ice in the form of Undetermined/Unknown
  Predominant/secondary form: Predominant: Small Floe (20 m - 100 m across), Secondary: Undetermined/Unknown

Polygon 310 covers 4,547.43 km².
9/10 - 10/10 of this area is ice-covered, with the following stage distribution:
  - 3/10 in the stage of Multi Year Ice in the form of Big Floe (500 m - 2 km across)
  - 2/10 in the stage of Second Year Ice in the form of Big Floe (500 m - 2 km across)
  - 5/10 in the stage of Thin First Year Ice (30-70 cm thickness) in the form of Medium Floe (100 m - 500 m across)
  Predominant/secondary form: Predominant: Medium Floe (100 m - 500 m across), Secondary: Big Floe (500 m - 2 km across)

Polygon 311 covers 1,420.00 km².
9/10 - 10/10 of this area is ice-covered, with the following stage distribution:
  - 2/10 in the stage of Grey-white ice (15-30 cm thickness) in the form of Medium Floe (100 m - 500 m across)
  - 4/10 in the stage of Grey ice (10-15 cm thickness) in the form of Small Floe (20 m - 100 m across)
  - 4/10 in the stage of New ice in the form of Undetermined/Unknown
  - < 1/10: Multi Year Ice
  Predominant/secondary form: Predominant: Small Floe (20 m - 100 m across), Secondary: Undetermined/Unknown

Polygon 312 only contains: Land.

Polygon 313 covers 13,193.65 km².
9/10 - 10/10 of this area is ice-covered, with the following stage distribution:
  - 6/10 in the stage of Grey-white ice (15-30 cm thickness) in the form of Medium Floe (100 m - 500 m across)
  - 3/10 in the stage of Grey ice (10-15 cm thickness) in the form of Small Floe (20 m - 100 m across)
  - 1/10 in the stage of New ice in the form of Undetermined/Unknown
  - < 1/10: Multi Year Ice
  Predominant/secondary form: Predominant: Medium Floe (100 m - 500 m across), Secondary: Small Floe (20 m - 100 m across) 

Created directory: C:/Users/.../IceChaRt_output/SIGRID3_text
Output saved to: C:/Users/.../IceChaRt_output/SIGRID3_text/IceChaRt_SIGRID3_20260410_124728.txt
```
---

## Study Area: `seaice_studyarea()`
```r
# To create plots easily using satellite data and ice charts, this function reprojects the raster to the ice chart’s CRS,
# masks out the land pixels if necessary, and clips the iceChart to the bounding box extent of the raster.

?seaice_studyarea

# In the following example, Sentinel-1 EW data in HH and HV polarisation is fitted to the Ice Chart.
# install.packages(c("curl", "piggyback"))
library(piggyback)
library(curl)

# Download the test data
IceChaRt::download_testdata_IceChaRt()

# load raster
co_pol_path    <- system.file("extdata", "s1_20201101_hh.tif", package = "IceChaRt")
cross_pol_path <- system.file("extdata", "s1_20201101_hv.tif", package = "IceChaRt")

s1_hh <- terra::rast(co_pol_path)
s1_hv <- terra::rast(cross_pol_path)

path <- system.file("extdata", "cis_SGRDREA_20201102T.gpkg", package = "IceChaRt")
ice_chart <- terra::vect(path)

IceChaRt::seaice_studyarea(shp = ice_chart, tif = s1_hh)
IceChaRt::seaice_studyarea(shp = ice_chart, tif = s1_hv)

```
*Console output:*
```
> IceChaRt::download_testdata_IceChaRt()
Downloading example data to: C:/Users/.../IceChaRt/extdata
ℹ Downloading "s1_20201101_hh.tif"...
  |====================================================================================================================| 100%
ℹ Downloading "s1_20201101_hv.tif"...
  |====================================================================================================================| 100%
Data saved to: C:/Users/.../IceChaRt/extdata

> seaice_studyarea(shp = ice_chart, tif = s1_hh)
[...]
CRS do not match. Reprojecting SpatRaster to the CRS of the SpatVector.
Applying land mask using 'POLY_TYPE == L'...
Land mask applied.
Created directory: C:/Users/.../IceChaRt_output/study_area
Vector written to: C:/Users.../IceChaRt_output/study_area/clipped_icechart_20260410_153927.gpkg
Raster written to: C:/Users.../IceChaRt_output/study_area/masked_raster_20260410_153927.tif
$shp
 class       : SpatVector 
 geometry    : polygons 
 dimensions  : 19, 17  (geometries, attributes)
 extent      : 634560.3, 900949.7, 4005830, 4260447  (xmin, xmax, ymin, ymax)
 coord. ref. : WGS_1984_Lambert_Conformal_Conic 
 names       : ID_NEW      AREA PERIMETER    CT    CA    SA    FA    CB    SB    FB (and 7 more)
 type        :  <int>     <num>     <num> <chr> <chr> <chr> <chr> <chr> <chr> <chr>             
 values      :    262 2.376e+09 2.803e+05    80    20    85    05    20    84    04             
                  271 3.723e+10 1.806e+06    90    60    84    04    30    81    99             
                  284 2.238e+09 3.294e+05    91    10    85    05    60    84    04             

$tif
class       : SpatRaster 
size        : 6402, 6698, 1  (nrow, ncol, nlyr)
resolution  : 39.77149, 39.77149  (x, y)
extent      : 634560.3, 900949.7, 4005830, 4260447  (xmin, xmax, ymin, ymax)
coord. ref. : WGS_1984_Lambert_Conformal_Conic 
source(s)   : memory
name        : s1_20201101_hh 
min value   :   1.339771e-05 
max value   :   4.002907e+00
[...]
```
---

## RGB-Color Composite fpr Sentinel-1 EW/IW: `s1_seaice_rgb()`
```r
# Martin Raspaud and Mikhail Itkin have created a color composite using dual-polarized Sentinel-1 data
# in EW or IW mode that highlights the development stage of sea ice. The following function generates
# this composite using preprocessed, linear Sentinel-1 TIFF files.

?s1_seaice_rgb

r_hh <- terra::rast("IceChaRt_output/study_area/masked_raster_20260410_153927.tif")
r_hv <- terra::rast("IceChaRt_output/study_area/masked_raster_20260410_154430.tif")

s1_seaice_rgb(co_pol = co_pol, cross_pol = cross_pol, mode = "EW")
```
*Console output:*
```
RGB composite (EW mode, INT2U) written to: C:/Users/.../IceChaRt_output/s1_rgb/sea_ice_rgb_ew_20260410_161754.tif
```
---
---

# Let´s take a look at the created data
```r
# Please use the code with the data you have created, as the files are saved with a timestamp .
# Lets take a look at the data before...
terra::plot(s1_hh,  col = gray.colors(256, start = 0, end = 1), main="HH-Polarisation")
terra::plot(s1_hv,  col = gray.colors(256, start = 0, end = 1), main="HV-Polarisation")

# ... and after using the function:
r_hh <- terra::rast("IceChaRt_output/study_area/masked_raster_20260410_153927.tif")
r_hv <- terra::rast("IceChaRt_output/study_area/masked_raster_20260410_154430.tif")
terra::plot(r_hh, col = gray.colors(256, start = 0, end = 1), main="HH-Polarisation-Newly projected and applied land mask")
terra::plot(r_hv , col = gray.colors(256, start = 0, end = 1), main="HV-Polarisation-Newly projected and applied land mask")

# The clipped weekly Ice Chart
v_cis <- terra::vect("IceChaRt_output/study_area/clipped_icechart_20260410_154430.gpkg")
terra::plot(v_cis, "CT", main="Ice Chart - CT (Total ice concentration)")

# The RGB Color composite
rgb <- terra::rast("IceChaRt_output/s1_rgb/sea_ice_rgb_ew_20260410_161754.tif")
rgb_plot <- terra::clamp(rgb / 10000, 0, 1)
terra::plotRGB(rgb_plot, r = 1, g = 2, b = 3, stretch = "lin")

```
|                                     |                                                       |
| :-------------------                                                                 | :----------                                                                                  | 
|![HH](https://github.com/user-attachments/assets/4875c6ec-61b4-421d-8906-ad79d15240ed)|![HV](https://github.com/user-attachments/assets/44e3e3f4-5c70-470b-b013-2c4731c29f14)        |
|![HH_new](https://github.com/user-attachments/assets/0d0578ed-0c9a-46a1-94fe-797dab567733)|![HV_new](https://github.com/user-attachments/assets/d57f1247-8e7e-47cb-9dad-0df71125d6fd)|
|![ice](https://github.com/user-attachments/assets/095409cf-8d07-4339-8272-47ccb1b9e015)|![rgb](https://github.com/user-attachments/assets/074e946b-b472-460e-bbbd-ce829756eb83)|

---
---
# References
<a name="source1" />

- [1] World Meteorological Organization (2017): *SIGRID-3: A vector archive format for Sea ICe georeferenced information and data. Version 3.1, WMO/TD-No. 1214.* <https://download.dmi.dk/public/ICESERVICE/2024_download_readme/ETSI6-Doc-3%201%202-SIGRID-3_1_App_A_SIGRID3_rev3-1_v5.pdf>
<a name="source2" />

- [2] Government of Canada (2017): *The Egg Code.* <https://www.canada.ca/en/environment-climate-change/services/ice-forecasts-observations/publications/interpreting-charts/chapter-1.html>
<a name="source3" />

- [3] Raspaud, M., Itkin, M. (2020): *SAR-Ice: A Sea Ice RGB Composite.* <https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/>
<a name="source4" />

- [4] Danish Meteorological Institute: *Additional information related to data.* <https://download.dmi.dk/public/ICESERVICE/2024_download_readme/README_download_dmi_dk.pdf>
<a name="source5" />

- [5] Canadian Ice Service (2026): *Latest ice conditions.* <https://www.canada.ca/en/environment-climate-change/services/ice-forecasts-observations/latest-conditions.html>
<a name="source6" />

- [6]: U.S. National Ice Center (2026): https://usicecenter.gov/
---
# Data Source
<a name="source7" />

- [7] Canadian Ice Service (2026): *Ice Charts.* <https://noaadata.apps.nsidc.org/NOAA/G02171/>
- U.S. National Ice Center (2026): *Ice Charts.* <https://noaadata.apps.nsidc.org/NOAA/G10013/>
- Danish Meteorological Institute (2026): *Ice Charts.* <https://download.dmi.dk/public/ICESERVICE/>
- European Space Agency (2020): *S1B_EW_GRDM_1SDH_20201101T214550_20201101T214650_024077_02DC57_E104*
- Canadian Ice Service (2020): cis_SGRDREA_20201102T1800Z_pl_a


![sea_ice_rgb_ew_20260410_213805](https://github.com/user-attachments/assets/7d03a373-5c06-4743-ae4d-fe0e7b2c195c)

