def parse_to_horde(payload, model, image, args):
    out = {
        "prompt": payload["prompt"],
        "params": {
            "sampler_name": "k_lms",
            "toggles": [
                1,
                4
            ],
            "cfg_scale": payload["cfg_scale"],
            "denoising_strength": payload['denoising_strength'],
            "seed": str(payload["seed"]),
            "height": payload['height'],
            "width": payload['witdh'],
            "seed_variation": 1,
            "karras": True,
            "tiling": False,
            "hires_fix": payload["enable_hr"],
            "clip_skip": 1,
            "control_type": payload["ctrlnet_module"],
            "image_is_control": not (args.ctrlnet_model is None),
            "steps": payload['steps'],
            "n": ['n_iter'],
            "post_processing": [
                "CodeFormers"
            ]
        },
        "nsfw": True,
        "trusted_workers": True,
        "censor_nsfw": False,
        "models": [
            model
        ],
        "source_image": image,
        "r2": True,
        "shared": False
    }
