"""Extract static TTF weights from a variable font."""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

SRC = Path(sys.argv[1])
WEIGHTS = {
    "Light": 300,
    "Regular": 400,
    "Medium": 500,
    "SemiBold": 600,
    "Bold": 700,
}

for name, w in WEIGHTS.items():
    f = TTFont(str(SRC))
    inst = instantiateVariableFont(f, {"wght": w})
    out = SRC.parent / f"SpaceGrotesk-{name}.ttf"
    inst.save(str(out))
    print(out.name)
