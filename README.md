# IceChaRt
An R package to help you get started with the topic of sea ice.

**IceChaRt** allows users to search for and download sea ice charts, retrieve standardized vector data in the _Sea Ice GeoReferenced Information and Data_ (SIGRID-3) format, and extract egg code information for sea ice classification [[1](#source1), [2](#source2)]. **IceChaRt** also provides a function for colourising Sentinel-1 EW/IW dual-polarisation SAR images into RGB GeoTIFFs following the sea-ice composite by _Martin Raspaud_ and _Mikhail Itkin_, where co-polarisation (HH or VV) and cross-polarisation (HV or VH) are combined to emphasise different stages of sea-ice development [[3](#source3)].

![EggCode](https://github.com/user-attachments/assets/d2147f3a-56b7-46c2-b228-464724da1461 "EggCode")

Image: Egg Code [[2](#source2)]

---
## Package Functions

| Function             | Description  |Output |
| :------------------- | :---------- | :---------- |
| `search_cis_icechart()`  | Searches for weekly ice charts from the Canadian Ice Service for a given region and year.| A list of matching ice charts printed to the user's console. |
| `download_cis_icechart()`| Downloads an ice chart, adds a new ID column, and saves it as an `sf` object. |An `sf` object containing ice chart polygons and unique IDs.|
| `seaice_studyarea()`     | Clips an ice-chart `SpatVector` to the extent of a `SpatRaster`, with optional reprojection and land masking.| A cropped `SpatVector` and a land-masked, reprojected `SpatRaster`. |
| `read_sigrid3()`        | Interprets the SIGRID3 code for a sea-ice polygon. | A text file containing the polygon description.|
| `s1_seaice_rgb()`       | Creates a false-color sea-ice RGB composite from Sentinel-1 dual-polarization SAR data.| An RGB `SpatRaster`. |
| `download_testdata_IceChaRt`| Downloads bigger test data for the IceChaRt package.| `SpatRaster` |
---
## Example Workflow

### Install Package
```r
remotes::install_github("silbusch/IceChaRt")
library(IceChaRt)
```
### Search Ice Chart
```r
# Search for an ice chart, e.g., from the Canadian Ice Service:
IceChaRt::search_cis_icechart(region="Eastern_Arctic", year="2020")
```
*Console output:*
```
                                          filename
1                 cis_SGRDREA_20191230T1800Z_pl_a.tar
2                 cis_SGRDREA_20200106T1800Z_pl_a.tar
3                 cis_SGRDREA_20200113T1800Z_pl_a.tar
[...]
57                cis_SGRDREA_20201228T1800Z_pl_a.tar
                                                                                                                  url
1                 https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20191230T1800Z_pl_a.tar
2                 https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20200106T1800Z_pl_a.tar
3                 https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20200113T1800Z_pl_a.tar
[...]
57                https://noaadata.apps.nsidc.org/NOAA/G02171/Eastern_Arctic/2020/cis_SGRDREA_20201228T1800Z_pl_a.tar

        datum version standard
1  2019-12-30       a     TRUE
2  2020-01-06       a     TRUE
3  2020-01-13       a     TRUE
[...]
57 2020-12-28       a     TRUE
```
### Download Ice Chart
```r
# Download the Ice Chart
# If you do not specify a destination folder, the IceChaRt_output folder will
# be created in your working directory.

# The column ID_NEW is alwas is always created, because not all charts have unique polygon IDs 
IceChaRt::download_cis_icechart(target_date = "2020-11-02",
                      region = "Eastern_Arctic",
                      out_dir  = NULL)
```
*Console output:*
```
CIS Ice Chart written to: C:/Users/.../IceChaRt_output/icechart_cis/cis_SGRDREA_20201102T1800Z_pl_a_with_new_id.gpkg

Simple feature collection with 432 features and 17 fields
Geometry type: POLYGON
Dimension:     XY
Bounding box:  xmin: -195054.2 ymin: 2723279 xmax: 1970719 ymax: 5186461
Projected CRS: WGS_1984_Lambert_Conformal_Conic
First 10 features:
   ID_NEW        AREA PERIMETER   CT   CA   SA   FA   CB   SB   FB   CC   SC   FC   CN   CD   CF POLY_TYPE
1       1      317180   2926.12 <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA> <NA>         L
2       2   534223818 296911.74   50   -9   81   99   -9   -9   -9   -9   -9   -9   -9   -9 99-9         I
3       3   234814486 184996.95   20   -9   81   99   -9   -9   -9   -9   -9   -9   -9   -9 99-9         I
[...]
                         geometry
1  POLYGON ((818442.7 2847359,...
2  POLYGON ((586088.4 2852757,...
3  POLYGON ((623515.4 2860186,...
[...]
```
---
## References
<a name="source1" />

- [1] World Meteorological Organization (2017): SIGRID-3: A vector archive format for Sea ICe georeferenced information and data. Version 3.1, WMO/TD-No. 1214. <https://download.dmi.dk/public/ICESERVICE/2024_download_readme/ETSI6-Doc-3%201%202-SIGRID-3_1_App_A_SIGRID3_rev3-1_v5.pdf>
<a name="source2" />

- [2] Government of Canada (2017): The Egg Code. <https://www.canada.ca/en/environment-climate-change/services/ice-forecasts-observations/publications/interpreting-charts/chapter-1.html>
<a name="source3" />

- [3] Raspaud, M., Itkin, M. (2020): SAR-Ice: A Sea Ice RGB Composite. <https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/>
