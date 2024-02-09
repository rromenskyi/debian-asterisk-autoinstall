#!/usr/bin/env python3
import asyncio
import base64
import io
import os
import websockets
from google.cloud import speech_v1p1beta1
from google.oauth2 import service_account

# Load Google Cloud credentials from environment variable
credentials = service_account.Credentials.from_service_account_file(
    os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
)

# Initialize the Speech-to-Text client
speech_client = speech_v1p1beta1.SpeechClient(credentials=credentials)

# Define the configuration for the audio input
config = {
    "encoding": speech_v1p1beta1.RecognitionConfig.AudioEncoding.LINEAR16,
    "sample_rate_hertz": 8000,
    "language_code": "en-US",
}

async def process_audio(audio_data):
    # Decode the base64 audio data
    audio_content = base64.b64decode(audio_data)

    # Perform Speech-to-Text recognition
    audio = {"content": audio_content}
    response = await speech_client.recognize(config=config, audio=audio)

    # Extract transcription from response
    transcription = ""
    for result in response.results:
        transcription += result.alternatives[0].transcript + " "

    print("Updated transcription:", transcription)

async def handle_audio(websocket, path):
    while True:
        # Receive audio data from the WebSocket client
        audio_data = await websocket.recv()
        await process_audio(audio_data)

start_server = websockets.serve(handle_audio, "localhost", 8080)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
