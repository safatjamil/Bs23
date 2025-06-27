from flask import Flask, jsonify
import requests
import json
import yaml
import datetime
app = Flask(__name__)

# Global variables
dhk_lat  = '23.78'
dhk_long = '90.40'
timeout = '10'
dateTime = datetime.datetime.now()
now = dateTime.strftime('%Y') + '-' + dateTime.strftime('%m') + '-' + dateTime.strftime('%d') + ' ' + dateTime.strftime('%H:%M')


# Read configuration and version info
with open('config.yaml', 'r') as file:
    conf = yaml.safe_load(file)
with open('version.yaml', 'r') as file:
    version = yaml.safe_load(file)


@app.route('/api/hello', methods=['GET'])
def weather_api():
    res = {'hostname': conf['hostname'], 'datetime': now, 'version': version['apiVersion']}
    # Fetch data from the fetch_api function
    dhk_wx = fetch_api(dhk_lat, dhk_long)
    if dhk_wx['status'] == 'ok':
        res['weather'] = {"dhaka": {}}
        res['weather']['dhaka'] = {'temperature': dhk_wx['data']['current']['temperature_2m'], 
                                   'temp_unit': dhk_wx['data']['current_units']['temperature_2m']}
        return jsonify(res), 200
    else:
        res['error_message'] = dhk_wx['message']
        return jsonify(res), 503


@app.route('/api/health', methods=['GET'])
def health_api():
    res = {'hostname': conf['hostname'], 'datetime': now, 'version': version['apiVersion'], 'thirdPartyApiReach': False}
    dhk_wx = fetch_api(dhk_lat, dhk_long)
    # Fetch data from the fetch_api function
    if dhk_wx['status'] == 'ok':
        res['thirdPartyApiReach'] = True
    return jsonify(res), 200
    

# Fetch weather data from a third party API
def fetch_api(lat, long):
    url = f'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={long}&current=temperature_2m'
    ret = {'status': 'err', 'message': 'Could not fetch weather API now.', 'data': ''}
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            ret['status'] = 'ok'
            ret['message'] = 'Can fetch weather API successfully.'
            ret['data'] = json.loads(resp.text)
            
    except:
        ret['message'] = 'Something went wrong'
    return ret

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)