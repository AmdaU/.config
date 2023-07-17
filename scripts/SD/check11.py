#!/bin/python3
import argparse
import json
import requests
import io
import base64
from PIL import Image, PngImagePlugin
from time import sleep

def file_to_base64(path):
    pil_image = Image.open(path)
    with io.BytesIO() as stream:
        pil_image.save(stream, "PNG", pnginfo=None)
        base64_str = str(base64.b64encode(stream.getvalue()), "utf-8")
        return "data:image/png;base64," + base64_str


# Argument parsing ----------------------------------------------------------------------------
parser = argparse.ArgumentParser()
parser.add_argument('--url', help='url of the server', type=str)
args = parser.parse_args()

url = args.url if args.url else "http://127.0.0.1:7860"
while True:
    response = requests.get(url=f'{url}/sdapi/v1/progress')
    if not response.json()['current_image'] is None:
        im = response.json()['current_image']
        image = Image.open(io.BytesIO(base64.b64decode(im.split(",", 1)[0])))
        image.show()
    sleep(2)
