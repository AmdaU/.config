#!/bin/python3
import argparse
import json
import requests
import io
import base64
from PIL import Image, PngImagePlugin

pil_image = Image.open("/home/amda/scripts/SD/del_2.png")


#Convert image to base64
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

if args.url:
    url = args.url

if args.model_name:
    models = requests.get(url=f'{url}/sdapi/v1/sd-models')
    # print(list(models.json())
    for i in models.json():
        if args.model_name in i['title']:
            model_name = i['model_name']

    option_payload = {
        "sd_model_checkpoint": f"{model_name}",
    }
    requests.post(url=f'{url}/sdapi/v1/options', json=option_payload)
    print("using model: " + model_name)

# with open('payload.json') as read:
# payload = json.load(read)

payload = {
    "init_images": [pil_to_base64(pil_image)],
    "prompt":
    "photo of Nell Hudson, (unbuttoned shirt:1.2), sexy, <lora:inniesbettervaginas_v11:1.2>, midriff, abs, hourglass body, smiling, spreading her legs, bedroom",
    "negative_prompt": "pants, panties",
    "height": 768,
    "width": 512,
    "steps": 30,
    "sampler_name": "DPM++ 2M Karras",
    "cfg_scale": 7,
    "enable_hr": False,
    "hr_upscaler": "Latent",
    "hr_scale": 2,
    "denoising_strength": 0.55,
    "n_iter": 1
}

for arg in args._get_kwargs():
    if not arg[1] is None and arg[0] in list(payload):
        payload[arg[0]] = arg[1]

print(payload)

response = requests.post(url=f'{url}/sdapi/v1/img2img', json=payload).json()

print(response)

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
