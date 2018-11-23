# random experiments in improving(?) cartographic representation

library(pacman)
p_load(tidyverse, sf, geosphere)

set.seed(123)

world <- read_csv("data-raw/world.csv") %>%
  select(admin, iso_n3, Longitude, Latitude)

# library(tmap)
# tmap_mode("view")
# # tmap_mode("plot")
# world_sf <- st_as_sf(world, wkt = "the_geom")
# qtm(world_sf)


# using USA only for testing
# numeric codes of countries do not work
X201801 <- read_csv("data-raw/201801.csv") %>%
  filter(partner == "United States of America") %>%
  filter(partner != "World") %>%
  select(reporter, reporter_code, partner, partner_code, netweight_kg) %>%
  mutate(partner_code = 840) %>%
  mutate(reporter_code = ifelse(reporter == "Switzerland", 756, reporter_code)) %>%
  mutate(reporter_code = ifelse(reporter == "India", 356, reporter_code))

flows <- left_join(X201801, world, by = c("partner_code" = "iso_n3")) %>%
  dplyr::rename(orig_long = Longitude, orig_lat = Latitude) %>%
  left_join(., world, by = c("reporter_code" = "iso_n3")) %>%
  dplyr::rename(dest_long = Longitude, dest_lat = Latitude) %>%
  select(-starts_with("admin")) %>%
  filter(!is.na(netweight_kg))

orig_dot <- flows %>%
  group_by(partner, orig_long, orig_lat) %>%
  summarise(netweight_total = sum(netweight_kg))

dest_dot <- flows %>%
  group_by(reporter, dest_long, dest_lat) %>%
  summarise(netweight_total = sum(netweight_kg))

# no offset, no masking
ggplot()+
  geom_curve(data = flows,
             aes(x = orig_long, y = orig_lat,
                 xend = dest_long, yend = dest_lat),
             arrow = arrow(angle = 10, ends = "first",type = "closed"),
             # size = log10(flows$netweight_kg),
             alpha = 0.5, curvature = 0.15) +
  geom_point(data = orig_dot,
             aes(orig_long, orig_lat), size = 5,
             shape=21) +
  geom_point(data = dest_dot,
             aes(dest_long, dest_lat), size = 5,
             shape=21)  +
  theme_void()

ggsave("./images/arrows_raw.png")

# 'fake offset' using white fill & manual dest recalc
ggplot()+
  geom_curve(data = flows,
             aes(x = orig_long + (orig_long * 0.025),
                 y = orig_lat + (orig_lat * 0.025),
                 xend = dest_long,
                 yend = dest_lat),
             arrow = arrow(angle = 10, ends = "first",type = "closed"),
             # size = log10(flows$netweight_kg),
             alpha = 0.5, curvature = 0.15) +
  geom_point(data = orig_dot,
             aes(orig_long, orig_lat), size = 5,
             shape=21, fill = "white") +
  geom_point(data = dest_dot,
             aes(dest_long, dest_lat), size = 5,
             shape=21, fill = "white") +
  theme_void()

# ###########################################
# creating great circle line
test <- flows %>%
  slice(1)

plot(greatCircle(c(5,52), c(-120,37), n=36))

plot(greatCircle(c(-112.4617, 45.67955), c(4.640651, 50.63982), n=36))


# ###########################################
# creating simple features
# one set of two locations, two flows between

orig <- st_point(x = c(-112.4617, 45.67955))
orig_buffer <- st_buffer(orig, 10)

dest <- st_point(x = c(4.640651, 50.63982))
dest_buffer <- st_buffer(dest, 10)

line <- st_linestring(rbind(c(-112.4617, 45.67955), c(4.640651, 50.63982)))

plot(line)
plot(st_geometry(line))
plot(orig, add = TRUE)
plot(orig_buffer, add = TRUE)
plot(dest, add = TRUE)
plot(dest_buffer, add = TRUE)

# difference used to remove last bits of lines
line_short <- line %>%
  st_difference(st_union(orig_buffer)) %>%
  st_difference(dest_buffer)

plot(line_short, col = "red", add = TRUE)

line_curve_from <- data.frame(x1 = line_short[1], x2 = line_short[3],
                              y1 = line_short[2], y2 = line_short[4])

ggplot() +
  geom_curve(data = line_curve_from, aes(x=x1, y=x2, xend=y1, yend=y2),
             arrow = arrow(angle = 10, ends = "first", type = "closed")) +
  geom_curve(data = line_curve_from, aes(x=y1, y=y2, xend=x1, yend=x2),
             arrow = arrow(angle = 10, ends = "first", type = "closed")) +
  geom_sf(data = orig_buffer) +
  geom_sf(data = dest_buffer) +
  # geom_sf(data = line_short, size = 1) +
  ylim(c(10, 80)) + xlab("") + ylab("")

ggsave("./images/arrows_concept.png")

# ###########################################
# creating simple features
# extending to multiple locations, one flow between

orig <-  st_as_sf(dest_dot, coords = c("dest_long", "dest_lat"), crs = 4326)
orig_buffer <- st_buffer(orig, 10)

dest <-  st_as_sf(orig_dot, coords = c("orig_long", "orig_lat"), crs = 4326)
dest_buffer <- st_buffer(dest, 10)

line <- st_linestring(rbind(c(-112.4617, 45.67955), c(4.640651, 50.63982)))

line <- st_linestring(cbind(flows$dest_long, flows$dest_lat,
                            flows$orig_long, flows$orig_lat),
                      dim = "XY")

t1 <-  st_as_sf(flows, coords = c("orig_long", "orig_lat"), crs = 4326) %>%
  select(-starts_with("orig"), -starts_with("dest"))
t2 <-  st_as_sf(flows, coords = c("dest_long", "dest_lat"), crs = 4326) %>%
  select(-starts_with("orig"), -starts_with("dest"))

t3 <- rbind(t1, t2) %>%
  arrange(reporter, partner)

line <- t3 %>%
  dplyr::group_by(reporter, partner) %>%
  dplyr::summarise(do_union=FALSE) %>%
  sf::st_cast("LINESTRING") %>%
  left_join(select(flows, reporter, partner, netweight_kg))

rm(t1, t2, t3)

plot(st_geometry(orig_buffer))
plot(st_geometry(dest_buffer), add = TRUE)
plot(st_geometry(orig), add = TRUE)
plot(st_geometry(dest), add = TRUE, col = "black")
plot(st_geometry(line), add = TRUE)

# difference used to remove last bits of lines
line_short <- line %>%
  st_difference(st_union(st_combine(orig_buffer))) %>%
  st_difference(st_union(st_combine(dest_buffer)))

st_line_sample(line_short, sample = 0)

plot(st_geometry(st_segmentize(line_short, dfMaxLength = 100)))

plot(line_short, col = "red", add = TRUE)

line_curve_from <- data.frame(x1 = line_short[1], x2 = line_short[3],
                              y1 = line_short[2], y2 = line_short[4])

ggplot() +
  geom_curve(data = line_curve_from, aes(x=x1, y=x2, xend=y1, yend=y2),
             arrow = arrow(angle = 10, ends = "first", type = "closed")) +
  geom_curve(data = line_curve_from, aes(x=y1, y=y2, xend=x1, yend=x2),
             arrow = arrow(angle = 10, ends = "first", type = "closed")) +
  geom_sf(data = orig_buffer) +
  geom_sf(data = dest_buffer) +
  # geom_sf(data = line_short, size = 1) +
  ylim(c(10, 80)) + xlab("") + ylab("")
