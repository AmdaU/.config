#!/bin/python3
import argparse
import json
import requests
import io
import base64
from PIL import Image, PngImagePlugin

pil_image = Image.open("/home/amda/Downloads/after_hours_by_2c3d_dfl5x7l-fullview.jpg")


def pil_to_base64(pil_image):
    with io.BytesIO() as stream:
        pil_image.save(stream, "PNG", pnginfo=None)
        base64_str = str(base64.b64encode(stream.getvalue()), "utf-8")
        return "data:image/png;base64," + base64_str


url = "http://127.0.0.1:7860"
parser = argparse.ArgumentParser()
parser.add_argument('-p',
                    '--prompt',
                    help='The prompt for the image',
                    type=str)
parser.add_argument('-o',
                    '--output',
                    help='The name of the output file',
                    type=str)
parser.add_argument('-m',
                    '--model_name',
                    help='substring or hash of the model to use',
                    type=str)
parser.add_argument('-n',
                    '--n_iter',
                    help='number of images to make',
                    type=int)
parser.add_argument('-s', '--steps', help='number of interations', type=int)
parser.add_argument('-u', '--url', help='url of the server', type=str)
parser.add_argument('-g', '--gfc_scale', help='gfc scale', type=int)
args = parser.parse_args()

img = pil_to_base64(pil_image)
# img = img + ('=' * (len(img) % 4))

payload_cn = {
    "controlnet_input_image": [img],
    "controlnet_module": "openpose",
    "controlnet_model": "controlnetPreTrained_openposeV10 [9ca67cc5]"
}

with open('payload.json') as read:
    payload = json.load(read)

# with open('payload_cn.json') as read:
# payload_cn = json.load(read)

payload.update(payload_cn)

print(payload)

if args.url:
    url = args.url

response = requests.post(url=f'{url}/sdapi/v1/options',
                         json={
                             "sd_vae":
                             "vae-ft-mse-840000-ema-pruned.safetensors"
                         }).json()

response = requests.post(url=f'{url}/controlnet/txt2img', json=payload).json()

for i, im in enumerate(response['images']):
    image = Image.open(io.BytesIO(base64.b64decode(im.split(",", 1)[0])))

    png_payload = {"image": "data:image/png;base64," + im}
    response2 = requests.post(url=f'{url}/sdapi/v1/png-info', json=png_payload)

    pnginfo = PngImagePlugin.PngInfo()
    pnginfo.add_text("parameters", response2.json().get("info"))
    image.save(
        f'{args.output.split(".")[0] if args.output else "output.png"}' +
        f'_{i}.png',
        pnginfo=pnginfo)
