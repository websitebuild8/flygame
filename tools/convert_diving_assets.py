#!/usr/bin/env python3
"""Convert the selected owner-authorized underwater hunting prop, not game code."""
from pathlib import Path
from convert_reference_assets import convert
source=Path('/home/ahusan/ft/split_UnityDataAssetPack/assets')
if __name__=='__main__':
 convert(next(source.glob('fishingaquariumscene_assets_aquarium02_*.bundle')),['crossbow02','crossbow02_scope'],['Idle01','Aim01','Shoot01','Appear01','Back01'],Path('assets/models/reference/speargun.glb'),512)
