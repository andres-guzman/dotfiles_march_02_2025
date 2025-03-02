#!/usr/bin/env python3

import subprocess
from pyquery import PyQuery  # install using `pip install pyquery`
import json
import os

# original code https://gist.github.com/Surendrajat/ff3876fd2166dd86fb71180f4e9342d7
# weather icons
weather_icons = {
    "sunnyDay": "󰖙",
    "clearNight": "󰖔",
    "cloudyFoggyDay": "",
    "cloudyFoggyNight": "",
    "rainyDay": "",
    "rainyNight": "",
    "snowyIcyDay": "",
    "snowyIcyNight": "",
    "severe": "",
    "default": "",
}

# get location_id
# to get your own location_id, go to https://weather.com & search your location.
# once you choose your location, you can see the location_id in the URL(64 chars long hex string)
# like this: https://weather.com/en-PH/weather/today/l/bca47d1099e762a012b9a139c36f30a0b1e647f69c0c4ac28b537e7ae9c1c200
location_id = "e6d1defce07d00acfafabd003e517802315e153db26c3c0b7b82ef8dc4cfad4b"

# NOTE to change to deg F, change the URL to your preffered location after weather.com
# Default is English-Philippines with Busan, South Korea as location_id
# get html page
url = "https://weather.com/en-CA/weather/today/l/" + location_id
html_data = PyQuery(url=url)


# current temperature
temp = html_data("span[data-testid='TemperatureValue']").eq(0).text()

# current status phrase
status = html_data("div[data-testid='wxPhrase']").text()

# status code
status_code = html_data("#regionHeader").attr("class").split(" ")[2].split("-")[2]

# status icon
icon = (
    weather_icons[status_code]
    if status_code in weather_icons
    else weather_icons["default"]
)

# temperature feels like
temp_feel = html_data("div[data-testid='FeelsLikeSection'] > span > span[data-testid='TemperatureValue']").text()
temp_feel_text = f"Feels like {temp_feel}C"

# min-max temperature
temp_min = (
    html_data("div[data-testid='wxData'] > span[data-testid='TemperatureValue']").eq(1).text()
)
temp_max = (
    html_data("div[data-testid='wxData'] > span[data-testid='TemperatureValue']").eq(0).text()
)
temp_min_max = f"Min: {temp_min} / Max: {temp_max}"

# wind speed
wind_speed = html_data("span[data-testid='Wind']").text().split("\n")[1]
wind_text = f"Wind speed: {wind_speed}"

# humidity
humidity = html_data("span[data-testid='PercentageValue']").text()
humidity_text = f"Humidity: {humidity}"

# visibility
visbility = html_data("span[data-testid='VisibilityValue']").text()
visbility_text = f"Visibility: {visbility}"

# air quality index
air_quality = html_data("text[data-testid='DonutChartValue']").text()
air_quality_text = f"Air quality index: {air_quality}"

# Hourly forecast
hourly_forecast = html_data("section[aria-label='Hourly Forecast']").text()

# Tooltip text
tooltip_text = str.format(
    "{}{}{}{}{}{}{}{}{}",
    f'<span size="xx-large">La Paz, Bolivia</span>\n\n',
    f'<span size="xx-large">{temp}C</span>\n',
    f"{temp_feel_text}\n\n",
    f"<big>{status} {icon}</big>\n\n",
    f"{temp_min_max}\n",
    f"{wind_text}\n",
    f"{humidity_text}\n",
    f"{visbility_text}\n",
    f"{air_quality_text}",
    # f"{hourly_forecast}",
)

# print waybar module data
out_data = {
    # "text": f"{temp}C {icon}",
    "text": f"{temp}C",
    "alt": status,
    "tooltip": tooltip_text,
    "class": status_code,
}
print(json.dumps(out_data))

simple_weather =f"{icon}  {status}\n" + \
                f"  {temp} ({temp_feel_text})\n" + \
                f"{wind_text} \n" + \
                f"{humidity_text} \n" + \
                f"{visbility_text} AQI{air_quality_text}\n"

try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as file:
        file.write(simple_weather)
except:
    pass
