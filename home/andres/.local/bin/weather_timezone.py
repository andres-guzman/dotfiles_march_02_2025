#!/usr/bin/env python

"""
weather_timezone.py

Fetches weather data and local date/time for a list of cities from OpenWeatherMap.
Cycles through cities when called with the argument "next".
Outputs a JSON object with keys "text" and "tooltip" that Waybar uses.

Usage:
  - To display the current city's info: run the script normally.
  - To cycle to the next city: run the script with the argument "next".
  
A state file (/tmp/current_city_index.txt) is used to persist the current city index.
Weather data is cached in /tmp/weather_cache.json to avoid excessive API requests.
"""

import requests
import json
import sys
from datetime import datetime
import pytz
import os
import pycountry
import time

# OpenWeatherMap API Key
API_KEY = "02a821687721a64a16cf83990f2ff186" 

# List of cities to cycle through.
# Each tuple is: (Display Name, Query for OWM, Timezone)
CITIES = [
    ('La Paz', 'La Paz,BO', 'America/La_Paz'),
    ('Amsterdam', 'Amsterdam,NL', 'Europe/Amsterdam'),
    ('Helsinki', 'Helsinki,FI', 'Europe/Helsinki'),
]

# File to store the current city index persistently
STATE_FILE = '/tmp/current_city_index.txt'
WEATHER_CACHE_FILE = '/tmp/weather_cache.json'

def read_index():
    try:
        with open(STATE_FILE, 'r') as f:
            idx = int(f.read().strip())
            if 0 <= idx < len(CITIES):
                return idx
    except Exception:
        pass
    return 0

def write_index(idx):
    with open(STATE_FILE, 'w') as f:
        f.write(str(idx))

def should_update_weather():
    """ Checks if we should update the weather data (only every 10 minutes). """
    try:
        if os.path.exists(WEATHER_CACHE_FILE):
            with open(WEATHER_CACHE_FILE, 'r') as f:
                cache = json.load(f)
                last_update = datetime.fromisoformat(cache.get('last_update'))
                if (datetime.now() - last_update).total_seconds() < 600:
                    return False, cache
    except Exception:
        pass
    return True, None

def save_weather_cache(data):
    """ Saves weather data to the cache file. """
    cache = {'last_update': datetime.now().isoformat(), 'weather': data}
    with open(WEATHER_CACHE_FILE, 'w') as f:
        json.dump(cache, f)

def get_weather_data(query):
    """ Fetches weather data from OpenWeatherMap with retry mechanism. """
    url = f'http://api.openweathermap.org/data/2.5/weather?q={query}&appid={API_KEY}&units=metric&lang=en'
    attempt = 0
    max_attempts = 10
    while attempt < max_attempts:
        try:
            response = requests.get(url, timeout=5)
            response.raise_for_status()
            return response.json(), None
        except requests.exceptions.RequestException as req_err:
            attempt += 1
            if attempt < max_attempts:
                time.sleep(5)  # Wait for 5 seconds before retrying
            else:
                return None, f"Request failed after {max_attempts} attempts: {req_err}"
    return None, "Request failed: unknown error"

# Read the current city index.
current_index = read_index()

# If the script is called with the argument 'next', cycle to the next city.
if len(sys.argv) > 1 and sys.argv[1] == 'next':
    current_index = (current_index + 1) % len(CITIES)
    write_index(current_index)

# Get the current city's details.
city_name, city_query, city_tz = CITIES[current_index]

# Get the local date and time for the city's timezone.
tz = pytz.timezone(city_tz)
local_dt = datetime.now(tz)
try:
    dt_str = local_dt.strftime("%A, %B %-d <span foreground='#46474A'>|</span> %-I:%M %p")
except Exception:
    dt_str = local_dt.strftime("%A, %B %d <span foreground='#46474A'>|</span> %I:%M %p").lstrip('0')

# Check if we should update weather data or use cached data
update_weather, cached_data = should_update_weather()

if update_weather:
    weather_data, error_message = get_weather_data(city_query)
    if weather_data:
        save_weather_cache(weather_data)
else:
    weather_data = cached_data['weather']

if weather_data is None:
    # Log the error
    with open("/tmp/weather_error.log", "a") as f:
        f.write(f"{datetime.now()}: {error_message}\n")

    waybar_text = f"<span foreground='#8c70fa'>{city_name}</span> {dt_str} <span foreground='#46474A'>|</span> (!) Weather Error"
    waybar_tooltip = (
        f"<span foreground='#8c70fa' size='14576'>{city_name}</span>\n\n"
        f"Local time: {dt_str}\n\n"
        f"Could not fetch weather data:\n{error_message}"
    )
else:
    # Extract weather details safely
    country_code = weather_data.get('sys', {}).get('country')
    country = pycountry.countries.get(alpha_2=country_code).name if pycountry.countries.get(alpha_2=country_code) else country_code

    temperature = round(weather_data['main']['temp'])
    feels_like = round(weather_data['main']['feels_like'])
    weather_desc = weather_data['weather'][0]['description'].capitalize()
    humidity = weather_data['main']['humidity']
    pressure = weather_data['main']['pressure']
    wind_speed = round(weather_data['wind']['speed'], 1)
    visibility = round(weather_data.get('visibility', 10000) / 1000)  # Convert meters to km
    cloudiness = weather_data['clouds']['all']  # Cloud coverage in %
    rain = weather_data.get('rain', {}).get('1h', 0)  # Rain volume in mm
    snow = weather_data.get('snow', {}).get('1h', 0)  # Snow volume in mm

    # Format the output for Waybar's text (concise version)
    waybar_text = f"<span foreground='#8c70fa'>{city_name}</span> {dt_str} <span foreground='#46474A'>|</span> {temperature}°C {weather_desc}"

    # Detailed weather info for tooltip
    waybar_tooltip = (
        f"<span foreground='#8c70fa' size='14576'>{city_name}, {country}</span>\n\n"
        f"{dt_str}\n\n"
        f"Temperature: {temperature}°C\n"
        f"Feels like: {feels_like}°C\n"
        f"Condition: {weather_desc}\n"
        f"Humidity: {humidity}%\n"
        f"Pressure: {pressure} hPa\n"
        f"Cloudiness: {cloudiness}%\n"
        f"Wind: {wind_speed} m/s\n"
        f"Visibility: {visibility} km\n"
        f"Rain: {rain} mm\n"
        f"Snow: {snow} mm"
    )

# Final JSON output for Waybar
result = {"text": waybar_text, "tooltip": waybar_tooltip}

# Print the JSON output for Waybar.
print(json.dumps(result, ensure_ascii=False))
