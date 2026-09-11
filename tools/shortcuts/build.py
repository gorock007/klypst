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


def if_block(group, variable_output, condition=100):
    """`condition` 100 = has any value. Returns (if, otherwise, end) actions."""
    return (
        action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=0,
               WFCondition=condition, WFInput={"Type": "Variable", "Variable": attachment(*variable_output)}),
        action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=1),
        None,  # end is built by the caller so its UUID can be referenced as "If Result"
    )


def end_if(group, ref):
    return action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=2, UUID=ref)


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
    """Get Clipboard → Get Images from Input → If images: Pick a Clip (Save Image First)
    / Otherwise: Pick a Clip (Save First: Clipboard) → If result has any value: Copy to Clipboard."""
    clipboard, images, pick_image, pick_text, end1, end2 = (uid() for _ in range(6))
    g1, g2 = uid(), uid()
    if1, else1, _ = if_block(g1, ("Images", images))
    if2, else2, _ = if_block(g2, ("If Result", end1))
    return workflow([
        action("is.workflow.actions.getclipboard", UUID=clipboard),
        action("is.workflow.actions.detect.images", UUID=images, WFInput=attachment("Clipboard", clipboard)),
        if1,
        intent("PickClipIntent", pick_image, saveImageFirst=attachment("Images", images)),
        else1,
        intent("PickClipIntent", pick_text, saveFirst=token_string("Clipboard", clipboard)),
        end_if(g1, end1),
        if2,
        action("is.workflow.actions.setclipboard", WFInput=attachment("If Result", end1)),
        else2,
        end_if(g2, end2),
    ])


def image_recipe():
    """Pick an Image Clip → Copy to Clipboard. Never opens Klypst."""
    pick = uid()
    return workflow([
        intent("PickImageClipIntent", pick),
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
