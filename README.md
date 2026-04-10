# IceChaRt
An R package to help you get started with the topic of sea ice.

**IceChaRt** allows users to search for and download sea ice charts, retrieve standardized vector data in the _Sea Ice GeoReferenced Information and Data_ (SIGRID-3) format, and extract egg code information for sea ice classification [[1](#source1), [2](#source2)]. **IceChaRt** also provides a function for colourising Sentinel-1 EW/IW dual-polarisation SAR images into RGB GeoTIFFs following the sea-ice composite by _Martin Raspaud_ and _Mikhail Itkin_, where co-polarisation (HH or VV) and cross-polarisation (HV or VH) are combined to emphasise different stages of sea-ice development [[3](#source3)].

![EggCode](https://github.com/user-attachments/assets/d2147f3a-56b7-46c2-b228-464724da1461 "EggCode")

Image: Egg Code [[2](#source2)]

---
## Regions
<img width="669" height="425" alt="image" src="https://github.com/user-attachments/assets/2a1801ff-01cd-4c39-bbbb-50d1ca3954bd" />

Image: Danish Meteorological Institute (DMI) regions [[5](#source5)].


<img width="594" height="471" alt="image" src="https://github.com/user-attachments/assets/79d39a9f-92cf-4798-8711-7bae3c489f90" />

Image: Canadian Ice Service (CIS) regions [[6](#source6)].

---
## Package Functions

| Function             | Description  |Output |
| :------------------- | :---------- | :---------- |
| `search_icechart()`  | Searches for weekly ice charts from the CIS, NIC or DMI for a given region and year.| A list of matching ice charts printed to the user's console. |
| `download_icechart()`| Downloads an ice chart, adds a new ID column, and saves it as an `sf` object. |An `sf` object containing ice chart polygons and unique IDs.|
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
### Download Ice Chart
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
terra::plot(v, "CT")
# Plot form of ice:
terra::plot(v, "FA")
```
*Console output:*
```
No encoding supplied: defaulting to UTF-8.
Downloading (1/1): cis_SGRDREA_20201102T1800Z_pl_a.tar
  |====================================================================================================================| 100%
  Converting to .gpkg: CIS_cis_SGRDREA_20201102T1800Z_pl_a.gpkg
Files saved to: C:/Users/.../IceChaRt_output/ice_charts
```
<img width="550" height="544" alt="ice_chart" src="https://github.com/user-attachments/assets/e58d5f75-7652-48bf-9abe-58a3f07149cc" /> 
<img width="550" height="544" alt="ice_chart_FA" src="https://github.com/user-attachments/assets/94a60585-e0ec-40f4-9c3a-b723ec843fb4" />


---
## References
<a name="source1" />

- [1] World Meteorological Organization (2017): SIGRID-3: A vector archive format for Sea ICe georeferenced information and data. Version 3.1, WMO/TD-No. 1214. <https://download.dmi.dk/public/ICESERVICE/2024_download_readme/ETSI6-Doc-3%201%202-SIGRID-3_1_App_A_SIGRID3_rev3-1_v5.pdf>
<a name="source2" />

- [2] Government of Canada (2017): The Egg Code. <https://www.canada.ca/en/environment-climate-change/services/ice-forecasts-observations/publications/interpreting-charts/chapter-1.html>
<a name="source3" />

- [3] Raspaud, M., Itkin, M. (2020): SAR-Ice: A Sea Ice RGB Composite. <https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-1/sar-ice/>

- [4] Danish Meteorological Institute. <https://download.dmi.dk/public/ICESERVICE/>
<a name="source5" />

- [5] Danish Meteorological Institute: Additional information related to data. <https://download.dmi.dk/public/ICESERVICE/2024_download_readme/README_download_dmi_dk.pdf>
<a name="source6" />

- [6] Canadian Ice Service (2026): Latest ice conditions. <https://www.canada.ca/en/environment-climate-change/services/ice-forecasts-observations/latest-conditions.html>
