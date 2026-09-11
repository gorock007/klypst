#!/usr/bin/env python3
"""Generates and signs the ready-made Klypst shortcuts bundled in the app.

    python3 tools/shortcuts/build.py

Writes Klypst/Resources/Shortcuts/*.shortcut (signed with `shortcuts sign --mode anyone`,
so any device can import them). Keep HelpView.manualRecipeSteps in step with `main_recipe`.
"""
import plistlib, subprocess, sys, uuid, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "Klypst" / "Resources" / "Shortcuts"
APP = {"AppIntentIdentifier": "", "BundleIdentifier": "com.klypst.app", "Name": "Klypst", "TeamIdentifier": "9PXJ82UU32"}


def uid():
    return str(uuid.uuid4()).upper()


def output(name, ref):
    return {"OutputName": name, "OutputUUID": ref, "Type": "ActionOutput"}


def attachment(name, ref):
    """A parameter that is exactly one variable (files, images, generic input)."""
    return {"Value": output(name, ref), "WFSerializationType": "WFTextTokenAttachment"}


def token_string(name, ref):
    """A text parameter whose whole content is one variable token."""
    return {
        "Value": {"attachmentsByRange": {"{0, 1}": output(name, ref)}, "string": "￼"},
        "WFSerializationType": "WFTextTokenString",
    }


def action(identifier, **params):
    return {"WFWorkflowActionIdentifier": identifier, "WFWorkflowActionParameters": params}


def intent(name, ref, **params):
    return action(f"com.klypst.app.{name}", AppIntentDescriptor={**APP, "AppIntentIdentifier": name}, UUID=ref, **params)


def workflow(actions, glyph=61440, color=-12365313):
    return {
        "WFQuickActionSurfaces": [],
        "WFWorkflowActions": actions,
        "WFWorkflowClientVersion": "4711",
        "WFWorkflowHasOutputFallback": False,
        "WFWorkflowHasShortcutInputVariables": False,
        "WFWorkflowIcon": {"WFWorkflowIconGlyphNumber": glyph, "WFWorkflowIconStartColor": color},
        "WFWorkflowImportQuestions": [],
        "WFWorkflowInputContentItemClasses": ["WFStringContentItem", "WFURLContentItem", "WFImageContentItem"],
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowTypes": ["WFWorkflowTypeShowInSearch"],
    }


def main_recipe():
    """Get Clipboard -> Pick a Clip (Save First: Clipboard) -> Copy to Clipboard.

    Deliberately linear. Wiring an empty variable (Get Images from Input on a text
    clipboard) into a file parameter fails resolution before the picker card can
    appear, so images live in `image_recipe` instead."""
    clipboard, pick = uid(), uid()
    return workflow([
        action("is.workflow.actions.getclipboard", UUID=clipboard),
        intent("PickClipIntent", pick, saveFirst=token_string("Clipboard", clipboard)),
        action("is.workflow.actions.setclipboard", WFInput=attachment("Pick a Clip", pick)),
    ])


def image_recipe():
    """Get Clipboard -> Get Images from Input -> Pick an Image Clip (Save First: Images)
    -> Copy to Clipboard. For Back Tap: saves a freshly copied image and pastes any saved
    one. Get Images from Input yields nothing for text, leaving Save First nil."""
    clipboard, images, pick = uid(), uid(), uid()
    return workflow([
        action("is.workflow.actions.getclipboard", UUID=clipboard),
        action("is.workflow.actions.detect.images", UUID=images, WFInput=attachment("Clipboard", clipboard)),
        intent("PickImageClipIntent", pick, saveFirst=attachment("Images", images)),
        action("is.workflow.actions.setclipboard", WFInput=attachment("Pick an Image Clip", pick)),
    ], glyph=59511)


def build(name, wf):
    OUT.mkdir(parents=True, exist_ok=True)
    unsigned = OUT / f"{name}.unsigned.shortcut"  # the signer insists on this extension
    signed = OUT / f"{name}.shortcut"
    with open(unsigned, "wb") as f:
        plistlib.dump(wf, f, fmt=plistlib.FMT_BINARY)
    subprocess.run(["shortcuts", "sign", "--mode", "anyone", "--input", str(unsigned), "--output", str(signed)], check=True)
    unsigned.unlink()
    print(f"signed {signed.relative_to(ROOT)} ({signed.stat().st_size} bytes)")


if __name__ == "__main__":
    build("Klypst", main_recipe())
    build("Klypst Images", image_recipe())
