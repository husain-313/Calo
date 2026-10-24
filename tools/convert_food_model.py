#!/usr/bin/env python3
"""Convert an open Food-101 image classifier (Hugging Face) to a Core ML model.

Output: Calo/Resources/FoodModel.mlpackage — an image classifier whose outputs
are the 101 Food-101 dish labels. Weights are 8-bit quantized to keep the file
small. The app loads it automatically via VNCoreMLRequest.

Run on macOS (CI) or any machine with torch + transformers + coremltools:
    python tools/convert_food_model.py
"""
import os
import torch
import coremltools as ct
from transformers import AutoImageProcessor, AutoModelForImageClassification

MODEL_ID = os.environ.get("FOOD_MODEL_ID", "nateraw/food")  # ViT fine-tuned on Food-101
OUT = os.environ.get("FOOD_MODEL_OUT", "Calo/Resources/FoodModel.mlpackage")


def main() -> None:
    print(f"Loading {MODEL_ID} …")
    processor = AutoImageProcessor.from_pretrained(MODEL_ID)
    model = AutoModelForImageClassification.from_pretrained(MODEL_ID).eval()

    id2label = model.config.id2label
    labels = [id2label[i] for i in range(len(id2label))]
    print(f"{len(labels)} classes, e.g. {labels[:5]}")

    # The classifier expects normalized pixels; expose softmax probabilities.
    class Wrapper(torch.nn.Module):
        def __init__(self, m):
            super().__init__()
            self.m = m

        def forward(self, x):
            return self.m(pixel_values=x).logits.softmax(-1)

    wrapper = Wrapper(model).eval()

    size = 224
    if isinstance(processor.size, dict):
        size = processor.size.get("height") or processor.size.get("shortest_edge") or 224

    example = torch.rand(1, 3, size, size)
    with torch.no_grad():
        traced = torch.jit.trace(wrapper, example)

    # nateraw/food (ViT) normalizes with mean=std=0.5 on all channels, so a
    # scalar scale + per-channel bias maps a 0–255 image into the model space:
    #   (pixel/255 - 0.5) / 0.5  ==  pixel * (1/127.5) - 1
    mean = processor.image_mean
    std = processor.image_std
    assert len(set(std)) == 1, f"non-uniform std {std} needs per-channel scale"
    scale = 1.0 / (255.0 * std[0])
    bias = [-m / s for m, s in zip(mean, std)]

    image_input = ct.ImageType(
        name="image",
        shape=(1, 3, size, size),
        scale=scale,
        bias=bias,
        color_layout=ct.colorlayout.RGB,
    )

    print("Converting to Core ML …")
    mlmodel = ct.convert(
        traced,
        inputs=[image_input],
        classifier_config=ct.ClassifierConfig(labels),
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.iOS16,
    )

    # 8-bit weight quantization to keep the package well under 100 MB.
    try:
        from coremltools.optimize.coreml import (
            OpLinearQuantizerConfig, OptimizationConfig, linear_quantize_weights,
        )
        cfg = OptimizationConfig(
            global_config=OpLinearQuantizerConfig(mode="linear_symmetric", weight_threshold=512)
        )
        print("Quantizing weights to 8-bit …")
        mlmodel = linear_quantize_weights(mlmodel, config=cfg)
    except Exception as exc:  # keep fp16 model if optimize API is unavailable
        print(f"Quantization skipped: {exc}")

    mlmodel.short_description = "Food-101 image classifier (converted for Calo, personal use)."
    mlmodel.author = MODEL_ID

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    mlmodel.save(OUT)
    print(f"Saved {OUT}")


if __name__ == "__main__":
    main()
