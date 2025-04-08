import speech_recognition as sr
import openai
#import whisper
from gtts import gTTS
import os
import io
import subprocess
import wave
import pasimple
# pip install --upgrade openai SpeechRecognition gTTS pasimple

#model = whisper.load_model("base")
#result = model.transcribe("audio.mp3")
#print(result["text"])

# OpenAI API
with open('.key') as f:
    openai.api_key = f.read().strip()

# Init speech
r = sr.Recognizer()

def listen_to_speech():
    with sr.Microphone() as source:
        print("Talk now...")
        audio = r.listen(source)
        try:
            text = r.recognize_google(audio, language='de-DE')
            print("You said: {}".format(text))
            return text
        except:
            print("Sorry, did not get your voice")
            return None

def send_to_gpt(text):
    if text is not None:
        try:
            response = openai.ChatCompletion.create(
              # model="gpt-3.5-turbo",
              model="gpt-4",
              messages=[
                    {"role": "system", "content": "You are a helpful chatbot."},
                    {"role": "user", "content": text},
                ]
            )
            return response['choices'][0]['message']['content']
        except Exception as e:
            print(f"Error: {e}")
            return None

def text_to_speech(text):
    if text is not None:
        tts = gTTS(text=text, lang='de', slow=False)
        tts.save("/tmp/test.mp3")
        os.remove("/tmp/test.wav")
        subprocess.run(['ffmpeg', '-i', '/tmp/test.mp3', '/tmp/test.wav'])
        os.remove("/tmp/test.mp3")
        with wave.open('/tmp/test.wav', 'rb') as wave_file:
            return wave_file.readframes(wave_file.getnframes())

def play(pa, sound_buffer):
    pa.write(sound_buffer)
    pa.drain()

def main():
    with pasimple.PaSimple(pasimple.PA_STREAM_PLAYBACK, 3, 1, 24000) as pa:
        while True:
            user_input = listen_to_speech()
            gpt_response = send_to_gpt(user_input)
            print("IT answered: {}".format(gpt_response))
            sound_buffer = text_to_speech(gpt_response)
            play(pa, sound_buffer)

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 1:
        main()
        raise "hi"
    else:
        with open(sys.argv[1]) as f:
            response = openai.ChatCompletion.create(
              model="gpt-3.5-turbo",
              messages=[
                    {"role": "system", "content": "You are an assistent helping correct and improve documentation written in Markdown syntax. Answer only in Markdown."},
                    {"role": "user", "content": f.read()},
                ]
            )
            print(response['choices'][0]['message']['content'])
