#!/bin/bash

# Publish large JSON messages for testing
# Requires mosquitto_pub (brew install mosquitto)

BROKER="${1:-test.mqtt.rnd7.de}"
PORT="${2:-1883}"

echo "Publishing large JSON messages to $BROKER:$PORT..."

# Generate pretty-printed JSON payload using python (much faster than bash loops)
generate_json() {
    local target_size=$1
    local name=$2

    python3 -c "
import json
import random
import string
from datetime import datetime

target_size = $target_size
name = '$name'

# Estimate items needed (each item is ~150 bytes when formatted)
num_items = max(1, (target_size - 200) // 150)

data = {
    'name': name,
    'targetBytes': target_size,
    'generated': datetime.now().isoformat(),
    'data': [
        {
            'id': i,
            'value': ''.join(random.choices(string.hexdigits.lower(), k=8)) + '-' +
                     ''.join(random.choices(string.hexdigits.lower(), k=4)) + '-' +
                     ''.join(random.choices(string.hexdigits.lower(), k=4)) + '-' +
                     ''.join(random.choices(string.hexdigits.lower(), k=4)) + '-' +
                     ''.join(random.choices(string.hexdigits.lower(), k=12)),
            'timestamp': 1700000000 + i,
            'active': i % 2 == 0,
            'score': round(random.uniform(0, 100), 2),
            'tags': ['sensor', 'mqtt', 'test']
        }
        for i in range(1, num_items + 1)
    ]
}

print(json.dumps(data, indent=2))
"
}

publish_large() {
    local size=$1
    local size_name=$2
    local topic="test/large/$size_name"

    echo "  Generating and publishing $size_name message to $topic..."
    generate_json "$size" "$size_name" | mosquitto_pub -h "$BROKER" -p "$PORT" -t "$topic" -s -q 1

    if [[ $? -eq 0 ]]; then
        echo "    ✓ Published $size_name"
    else
        echo "    ✗ Failed to publish $size_name"
    fi
}

# Publish messages of various sizes
publish_large 10240 "10KB"
publish_large 102400 "100KB"
publish_large 1048576 "1MB"
publish_large 2097152 "2MB"
publish_large 10485760 "10MB"

echo ""
echo "Done! Published large test messages to test/large/*"
