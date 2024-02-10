#!/usr/bin/env python3
import asyncio
import base64
import io
import os
import json
import websockets
from google.cloud import speech_v1p1beta1
from google.oauth2 import service_account
import phonenumbers
from phonenumbers import geocoder, carrier
import time
import asterisk.manager

def find_and_hangup(call_number):
    # Устанавливаем соединение с AMI
    manager = asterisk.manager.Manager()


    try:
        # Подключаемся к серверу Asterisk AMI
        manager.connect('ip')
        manager.login('login', 'password')

        # Получаем список активных каналов
        response = manager.send_action({'Action': 'Command', 'Command': 'core show channels concise'})

        # Разбиваем строку ответа на строки итерацией по ним
        for line in response.data.splitlines():
            # Разделяем строку по пробелам
            parts = line.split('!')
#            print(line)
            if len(parts) >= 10:
                # Получаем номер телефона из строки
                channel = parts[0]
                if call_number in line:
                    # Если найденный канал соответствует номеру, отправляем ему hangup
                    manager.send_action({'Action': 'Hangup', 'Channel': channel})
                    print(f"Hangup sent to {channel}")
                    break
    except Exception as e:
        print("An error occurred:", e)
    finally:
        # Закрываем соединение
        manager.close()

def validate_phone_number(phone_number):
    try:
        parsed_number = phonenumbers.parse(phone_number)
        valid = phonenumbers.is_valid_number(parsed_number)
        country = geocoder.description_for_number(parsed_number, 'en') if valid else 'Unknown'
        operator = carrier.name_for_number(parsed_number, 'en') if valid else 'Unknown'

        # Add the prefix "Mexico/" if the phone number starts with +52
        if valid and phone_number.startswith("+52"):
            country = "Mexico/" + country

        return valid, country, operator
    except phonenumbers.NumberParseException:
        return False, 'Unknown', 'Unknown'

def check_threshold(words, threshold):
    return len(words) >= threshold


def search_data_by_key(file_name, key):
    with open(file_name, "r") as file:
        data = json.load(file)

    if key in data:
        return data[key]
    else:
        return "Key not found"

def count_matching_arrays(array1, array2, threshold):
    set1 = set(array1)
    set2 = set(array2)

    intersection = set1.intersection(set2)

    if len(intersection) >= threshold and len(array1) >= threshold:
        return True
    else:
        return False


# Load Google Cloud credentials from environment variable
credentials = service_account.Credentials.from_service_account_file(
    os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
)

speech_client = speech_v1p1beta1.SpeechClient(credentials=credentials)

# Define the configuration for the audio input
config = {
    "encoding": speech_v1p1beta1.RecognitionConfig.AudioEncoding.LINEAR16,
    "sample_rate_hertz": 8000,
    "language_code": "es",
}

# Threshold for buffering audio data before recognition
bytes_threshold = 1024 * 50
recv = 0
buffers = []

async def process_audio(audio_data, response_array):
    global recv, buffers
    try:
        buffers.append(audio_data)
        recv += len(audio_data)
        
        if recv >= bytes_threshold:
            # Concatenate buffered audio data
            audio_content = b''.join(buffers)
            
            # Encode audio data to base64
            audio_content_base64 = base64.b64encode(audio_content).decode('utf-8')
            
            # Perform Speech-to-Text recognition
            audio = {"content": audio_content_base64}
            response = speech_client.recognize(config=config, audio=audio)

            # Reset buffer and counter
            recv = 0
            buffers = []

            # Process recognition response
            for result in response.results:
                text = result.alternatives[0].transcript.lower()
                print("Recognized text:", text)
                words = text.split()
                response_array.extend(words)


    except Exception as e:
        print("Error occurred during speech recognition:", e)

async def handle_audio(websocket, path):
    try:
        text_array = []
        url = websocket.path
        phone = path.split('/')[-1]
#        print('Phone is: ' + phone)
        valid, country, operator = validate_phone_number(phone)
        keywords = search_data_by_key("data.json", f"{country}/{operator}")

        while True:
            audio_data = await websocket.recv()
            await process_audio(audio_data,text_array)
            print(text_array)
            if count_matching_arrays(keywords, text_array, 2):
                if phone.startswith('+'):
                    phone  = phone_number.lstrip('+')
                    find_and_hangup(phone_number)
                    print('Answering machine detected')

    except websockets.exceptions.ConnectionClosedError:
        print("WebSocket connection closed by client")

start_server = websockets.serve(handle_audio, "localhost", 8080)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
