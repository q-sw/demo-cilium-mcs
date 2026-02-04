import json
import sys
import re

def process_cast(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    header = lines[0]
    events = lines[1:]
    new_events = []

    # Regex pour capturer nos marqueurs (non-greedy pour éviter d'avaler plusieurs marqueurs)
    marker_regex = re.compile(r'::MARKER::(.*?)::')

    for event_str in events:
        try:
            event = json.loads(event_str)
        except json.JSONDecodeError:
            continue

        timestamp, event_type, data = event

        if event_type == "o":
            matches = marker_regex.findall(data)
            if matches:
                # Ajout des événements marqueurs
                for label in matches:
                    new_events.append([timestamp, "m", label])

                # Nettoyage : on retire les balises mais on préserve tout le reste (\n, \r, couleurs)
                clean_data = marker_regex.sub('', data)

                if clean_data:
                    new_events.append([timestamp, "o", clean_data])
                continue

        new_events.append(event)

    with open(output_file, 'w') as f:
        f.write(header)
        for e in new_events:
            f.write(json.dumps(e) + '\n')

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python add_markers.py input.cast output.cast")
    else:
        process_cast(sys.argv[1], sys.argv[2])
