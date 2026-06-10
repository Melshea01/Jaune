import xml.etree.ElementTree as ET
import copy

def split_svg():
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")
    
    tree = ET.parse('assets/citron.svg')
    root = tree.getroot()
    
    # We need to preserve the definitions (defs) ideally, but in this file the gradients are defined inside the elements.
    # So we can just extract the groups.
    
    def find_group(element, group_id):
        for g in element.iter('{http://www.w3.org/2000/svg}g'):
            if g.get('id') == group_id:
                return g
        return None

    components = {
        'jambe_g': ['Jambe_G'],
        'jambe_d': ['Jambe_D'],
        'bras_g': ['Bras_G'],
        'bras_d': ['Bras_D'],
        'plante': ['Plante'],
        'corps': ['Corps', 'Taches', 'Cheveux'],
        'yeux': ['Oeuil_G', 'Oeuil_D'],
        'joues': ['Joue_G', 'Joue_D'],
        'bouche': ['Bouche']
    }

    viewbox = root.get('viewBox') or "-10 -20 420 440"
    width = root.get('width') or "420"
    height = root.get('height') or "420"

    print("Splitting...")
    for name, ids in components.items():
        new_root = ET.Element('{http://www.w3.org/2000/svg}svg')
        new_root.set('xmlns', "http://www.w3.org/2000/svg")
        new_root.set('xmlns:xlink', "http://www.w3.org/1999/xlink")
        new_root.set('width', width)
        new_root.set('height', height)
        new_root.set('viewBox', viewbox)
        
        for g_id in ids:
            g = find_group(root, g_id)
            if g is not None:
                new_root.append(copy.deepcopy(g))
            else:
                print(f"Warning: ID {g_id} not found!")
                
        with open(f'assets/citron_{name}.svg', 'wb') as f:
            tree_out = ET.ElementTree(new_root)
            tree_out.write(f, xml_declaration=False, encoding='utf-8')
    print("Done!")

if __name__ == '__main__':
    split_svg()
