# @title Weather from the Internet
# @category Tools
# @kind Console program
# @where Save as weather.py and run: python3 weather.py (needs internet, no API key needed).
# @keywords python weather api, python json api, python open-meteo, python urllib json, python forecast
# @about Looks up a city and shows the current temperature and a 3 day forecast from the free Open-Meteo service.

import json
import urllib.error
import urllib.parse
import urllib.request

WEATHER_CODES = {0: "clear sky", 1: "mostly clear", 2: "partly cloudy", 3: "cloudy", 45: "foggy", 51: "drizzle",
                 61: "light rain", 63: "rain", 65: "heavy rain", 71: "light snow", 73: "snow", 75: "heavy snow",
                 80: "rain showers", 95: "thunderstorm"}


def get_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "python-learning-script"})
    with urllib.request.urlopen(request, timeout=10) as response:
        return json.loads(response.read().decode("utf-8"))


city = input("City name: ").strip() or "London"
try:
    # Step 1: turn the city name into latitude and longitude
    query = urllib.parse.urlencode({"name": city, "count": 1})
    places = get_json(f"https://geocoding-api.open-meteo.com/v1/search?{query}").get("results")
    if not places:
        raise SystemExit("I couldn't find that city.")
    place = places[0]

    # Step 2: ask for the weather at that spot
    query = urllib.parse.urlencode({
        "latitude": place["latitude"], "longitude": place["longitude"],
        "current_weather": "true", "daily": "temperature_2m_max,temperature_2m_min,weathercode",
        "timezone": "auto", "forecast_days": 3,
    })
    data = get_json(f"https://api.open-meteo.com/v1/forecast?{query}")
except urllib.error.URLError as error:
    raise SystemExit(f"Couldn't reach the weather service: {error}")

now = data["current_weather"]
print(f"\nWeather in {place['name']}, {place.get('country', '')}")
print(f"Right now: {now['temperature']} C, {WEATHER_CODES.get(now['weathercode'], 'mixed weather')}, wind {now['windspeed']} km/h")
daily = data["daily"]
for day, high, low, code in zip(daily["time"], daily["temperature_2m_max"], daily["temperature_2m_min"], daily["weathercode"]):
    print(f"  {day}: {low} to {high} C, {WEATHER_CODES.get(code, 'mixed weather')}")
