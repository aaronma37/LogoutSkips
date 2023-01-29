from Voronoi import Voronoi
import os
import json
from pathlib import Path

file_path = os.path.dirname(os.path.realpath(__file__))

def toLua(input_string):
    output_string = input_string.replace('[', '{')
    output_string = output_string.replace(']', '}')
    output_string = output_string.replace(')', '}')
    output_string = output_string.replace('(', '{')
    return output_string

f = open('gyClassic.json')
gy_locs = json.load(f)
f.close()

kalimdor_locs_set = set()
kalimdor_gy_locs_set = set()
for v in gy_locs['1']:
    kalimdor_locs_set.add((v['x'],v['y']))
    if 'graveyard' in v and v['graveyard'] == 1:
        kalimdor_gy_locs_set.add((v['x'], v['y']))

eastern_kingdom_locs_set = set()
eastern_kingdom_gy_locs_set = set()
for v in gy_locs['0']:
    eastern_kingdom_locs_set.add((v['x'],v['y']))
    if 'graveyard' in v and v['graveyard'] == 1:
        eastern_kingdom_gy_locs_set.add((v['x'], v['y']))

f = open('instances.json')
instance_locs = json.load(f)
f.close()

for v in instance_locs['1']:
    kalimdor_locs_set.add((v['x'],v['y']))

for v in instance_locs['0']:
    eastern_kingdom_locs_set.add((v['x'],v['y']))

eastern_kingdom_locs = list(eastern_kingdom_locs_set)
eastern_kingdom_gy_locs = list(eastern_kingdom_gy_locs_set)
kalimdor_locs = list(kalimdor_locs_set)
kalimdor_gy_locs = list(kalimdor_gy_locs_set)

p = Path('Data/eastern_kingdom_locs.lua')
p.open('w').write("eastern_kingdom_locs = " + toLua(json.dumps(eastern_kingdom_locs)))

p = Path('Data/eastern_kingdom_gy_locs.lua')
p.open('w').write("eastern_kingdom_gy_locs = " + toLua(json.dumps(eastern_kingdom_gy_locs)))

p = Path('Data/kalimdor_locs.lua')
p.open('w').write("kalimdor_locs = " + toLua(json.dumps(kalimdor_locs)))

p = Path('Data/kalimdor_gy_locs.lua')
p.open('w').write("kalimdor_gy_locs = " + toLua(json.dumps(kalimdor_gy_locs)))

vp = Voronoi(kalimdor_locs)
vp.process()
p = Path('Data/kalimdor_partitions.lua')
p.open('w').write("kalimdor_partitions = " + toLua(json.dumps(vp.get_output())))

vp = Voronoi(eastern_kingdom_locs)
vp.process()
p = Path('Data/eastern_kingdom_partitions.lua')
p.open('w').write("eastern_kingdom_partitions = " + toLua(json.dumps(vp.get_output())))

vp = Voronoi(eastern_kingdom_gy_locs)
vp.process()
p = Path('Data/eastern_kingdom_gy_partitions.lua')
p.open('w').write("eastern_kingdom_gy_partitions = " + toLua(json.dumps(vp.get_output())))

vp = Voronoi(kalimdor_gy_locs)
vp.process()
p = Path('Data/kalimdor_gy_partitions.lua')
p.open('w').write("kalimdor_gy_partitions = " + toLua(json.dumps(vp.get_output())))


# y = json.dumps(vp.get_output())
# y = y.replace('[', '{')
# y = y.replace(']', '}')
# print("kalimdor")
# print(y)

vp = Voronoi(eastern_kingdom_locs)
vp.process()
y = json.dumps(vp.get_output())
y = y.replace('[', '{')
y = y.replace(']', '}')
print("eastern kingdom")
print(y)
