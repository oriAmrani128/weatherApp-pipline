import os
import logging
import json
from datetime import datetime
from flask import Flask, render_template, request, send_file, Response
import requests
from dotenv import load_dotenv
from prometheus_client import generate_latest, Counter

# הגדרת הלוגים
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='app.log',
    filemode='a'
)

app = Flask(__name__)

load_dotenv()
API_KEY = os.getenv('API_KEY')
BASE_URL = os.getenv('BASE_URL')
HISTORY_FILE = "search_history.json"  

CITY_VIEW_COUNTER = Counter('city_views', 'Number of times each city has been looked at', ['city'])

@app.route('/')
def home():
    logging.info("Home page accessed")
    background_color = os.getenv('BG_COLOR', '#FFFFFF')
    return render_template('home.html', background_color=background_color)

@app.route('/results', methods=['POST'])
def results():
    location = request.form['location'].capitalize()
    logging.info(f"Request for weather data received for location: {location}")
    
    weather_url = f"{BASE_URL}{location}?unitGroup=metric&key={API_KEY}&contentType=json"
    geo_url = f"https://geocoding-api.open-meteo.com/v1/search?name={location}"

    try:
        geo_response = requests.get(geo_url, timeout=10)
        geo_response.raise_for_status()
    except requests.RequestException as e:
        logging.error(f"Error fetching location data for {location}: {e}")
        return render_template('home.html', error="Error fetching location data.")

    geo_data = geo_response.json()
    if 'results' not in geo_data or len(geo_data['results']) == 0:
        logging.warning(f"Location not found: {location}")
        return render_template('home.html', error="Location not found.")

    try:
        weather_response = requests.get(weather_url, timeout=10)
        weather_response.raise_for_status()
    except requests.RequestException as e:
        logging.error(f"Error fetching weather data for {location}: {e}")
        return render_template('home.html', error="Error fetching weather data")

    weather_data = weather_response.json()
    forecast = weather_data['days'][:7]  # Get the 7-day forecast
    country = geo_data['results'][0].get('country', 'Unknown')
    forecast_data = [{'date': day['datetime'], 'day_temp': day['tempmax'], 'night_temp': day['tempmin'], 'humidity': day['humidity']} for day in forecast]

    
    save_search_to_history(location, country)

    CITY_VIEW_COUNTER.labels(city=location).inc()
    logging.info(f"Weather data for {location} retrieved successfully")
   
    return render_template('results.html', forecast=forecast_data, location=location, country=country)

@app.route('/save_weather_data', methods=['POST'])
def save_weather_data():
    
    try:
        
        location = request.form.get('location')
        country = request.form.get('country')
        forecast = json.loads(request.form.get('forecast')) 

        
        file_name = f"{location}_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.json"
        file_path = os.path.join("saved_data", file_name)

      
        os.makedirs("saved_data", exist_ok=True)

       
        with open(file_path, 'w') as file:
            json.dump({
                "location": location,
                "country": country,
                "forecast": forecast,
                "saved_at": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }, file, indent=4)

        logging.info(f"Weather data for {location} saved successfully in {file_path}")
        return render_template("results.html", message="Weather data saved successfully!", location=location, country=country, forecast=forecast)
    except Exception as e:
        logging.error(f"Error saving weather data: {e}")
        return render_template("results.html", message="Error saving weather data.", location="", country="", forecast=[])

@app.route('/history')
def history():
    logging.info("History page accessed")
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'r') as file:
            history = json.load(file)
    else:
        history = []
    return render_template('history.html', history=history)

@app.route('/metrics')
def metrics():
    logging.info("Metrics endpoint accessed")
    return Response(generate_latest(), mimetype="text/plain")

def save_search_to_history(location, country):
    search_data = {
        "location": location,
        "country": country,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    history = []
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'r') as file:
            history = json.load(file)
    history.append(search_data)
    with open(HISTORY_FILE, 'w') as file:
        json.dump(history, file, indent=4)

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
