####uninhabited areas with R#####

libs <- c(
  "tidyverse", "terra", "giscoR"
)

installed_libs <- libs %in% rownames(
  installed.packages()
)

if (any(installed_libs == F)){
  install.packages(
      libs[!installed_libs]
  )
}

invisible(
  lapply(
      libs, library, character.only = T
  )
)

#Download the GHSL data 
library(httr)
url <-
  "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_4326_30ss/V1-0/GHS_POP_E2025_GLOBE_R2023A_4326_30ss_V1_0.zip"

file_name <- "GHS_POP_E2025_GLOBE_R2023A_4326_30ss_V1_0.zip"

response <- GET(url, write_disk(file_name, overwrite = TRUE), timeout(1000))

#load GHSL data
unzip(file_name)

raster_name <- gsub(
  ".zip", ".tif",
  file_name
)

pop <- terra::rast(raster_name)

# Türkiye Shapefile

get_country_borders <- function(){
    country <- giscoR::gisco_get_countries(
      country = "TUR",
      resolution = "3"
    )
    
    return(country)
}

country <- get_country_borders()

#crop türkiye ghsl
turkey_pop <- terra::crop(
  pop,
  terra::vect(country),
  snap = "in",
  mask = T
)

#raster to dataframe
tr_pop_df <- as.data.frame(
  turkey_pop,
  xy = T, na.rm = T
)

names(tr_pop_df)[3] <- "val"
tr_pop_df <- tr_pop_df |>
  dplyr::mutate(
      cat = dplyr::if_else(
          val > 0, "Yes", "No"
      )
  )

tr_pop_df$cat <- as.factor(
  tr_pop_df$cat
)

#map

cols <- c("#0a1c29", "#edc241")

p <- ggplot() +
  geom_raster(
      data = tr_pop_df,
      aes(x = x,
          y = y,
          fill = cat
      )
  )+
  scale_fill_manual(
      name = "Are there any people?",
      values = cols,
      na.value = "#0a1c29"
  ) +
  guides(
      fill = guide_legend(
          direction = "horizontal",
          keyheight = unit(5, "mm"),
          keywidth = unit(15, "mm"),
          label.position = "bottom",
          label.hjust = .5,
          nrow = 1,
          byrow = T
    )
  ) +
  theme_void() +
  theme(
      legend.position = "top",
      legend.title = element_text(
          size = 16, color = "grey10"
      ),
      legend.text = element_text(
          size = 14, color = "grey10"
      ),
      plot.caption = element_text(
          size = 10, color = "grey10",
          hjust = .25, vjust = 20
      ),
      plot.margin = unit(
        c(
            t = 0, b = -1,
            l= -1, r = -1
        ), "lines"
      )
  ) + 
  labs(
      title = "",
      caption = "Data: Global Human Settlement Layer at 30 arcsec"
  )
























