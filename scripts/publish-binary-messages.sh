#!/bin/bash

# Publish binary and image messages for testing
# Requires mosquitto_pub (brew install mosquitto)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BROKER="${1:-test.mqtt.rnd7.de}"
PORT="${2:-1883}"

echo "Publishing binary and image messages to $BROKER:$PORT..."

# Create a temporary directory for generated files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Path to the MQTTAnalyzer logo
LOGO_PATH="$PROJECT_ROOT/src/MQTTAnalyzer/Assets.xcassets/AppIcon.appiconset/App-Store-iOS.png"

# Generate a simple PNG image (1x1 red pixel)
generate_png() {
    # Minimal PNG: 1x1 red pixel
    printf '\x89PNG\r\n\x1a\n' > "$TEMP_DIR/test.png"
    printf '\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde' >> "$TEMP_DIR/test.png"
    printf '\x00\x00\x00\x0cIDATx\x9cc\xf8\xcf\xc0\x00\x00\x00\x03\x00\x01\x00\x05\xfe\xd4' >> "$TEMP_DIR/test.png"
    printf '\x00\x00\x00\x00IEND\xaeB`\x82' >> "$TEMP_DIR/test.png"
}

# Generate a test PNG using Python (more reliable)
generate_test_png() {
    local size=$1
    local filename=$2
    python3 -c "
import struct
import zlib

def create_png(width, height, color):
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc

    # PNG signature
    signature = b'\\x89PNG\\r\\n\\x1a\\n'

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # IDAT chunk (image data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\\x00'  # filter byte
        for x in range(width):
            # Create a gradient pattern
            r = int((x / width) * 255) if width > 1 else color[0]
            g = int((y / height) * 255) if height > 1 else color[1]
            b = color[2]
            raw_data += bytes([r, g, b])

    compressed = zlib.compress(raw_data)
    idat = png_chunk(b'IDAT', compressed)

    # IEND chunk
    iend = png_chunk(b'IEND', b'')

    return signature + ihdr + idat + iend

# Create test image
png_data = create_png($size, $size, (255, 100, 50))
with open('$filename', 'wb') as f:
    f.write(png_data)
"
}

# Generate a JPEG using system tools or Python PIL
generate_test_jpeg() {
    local size=$1
    local filename=$2

    # Try using sips (macOS) to convert PNG to JPEG
    if command -v sips &> /dev/null; then
        generate_test_png "$size" "$TEMP_DIR/temp_for_jpeg.png"
        sips -s format jpeg "$TEMP_DIR/temp_for_jpeg.png" --out "$filename" &> /dev/null
        rm -f "$TEMP_DIR/temp_for_jpeg.png"
        return
    fi

    # Try PIL
    python3 -c "
from PIL import Image

# Create a gradient image
img = Image.new('RGB', ($size, $size))
for x in range($size):
    for y in range($size):
        r = int((x / $size) * 255)
        g = int((y / $size) * 255)
        b = 128
        img.putpixel((x, y), (r, g, b))

img.save('$filename', 'JPEG', quality=85)
" 2>/dev/null || echo "Warning: Could not generate JPEG (install PIL or use macOS)"
}

# Generate random binary data
generate_binary() {
    local size=$1
    local filename=$2
    dd if=/dev/urandom of="$filename" bs=1 count="$size" 2>/dev/null
}

# Publish a file
publish_file() {
    local topic=$1
    local file=$2
    local description=$3

    if [ -f "$file" ]; then
        local size=$(wc -c < "$file" | tr -d ' ')
        echo "  Publishing $description ($size bytes) to $topic..."
        mosquitto_pub -h "$BROKER" -p "$PORT" -t "$topic" -f "$file" -q 1
        if [ $? -eq 0 ]; then
            echo "    ✓ Published"
        else
            echo "    ✗ Failed"
        fi
    else
        echo "    ✗ File not found: $file"
    fi
}

# Generate test files
echo "Generating test files..."

# Use MQTTAnalyzer logo if available, otherwise generate test images
if [ -f "$LOGO_PATH" ]; then
    echo "Using MQTTAnalyzer logo: $LOGO_PATH"
    cp "$LOGO_PATH" "$TEMP_DIR/logo.png"

    # Create smaller versions using sips
    if command -v sips &> /dev/null; then
        sips -z 16 16 "$LOGO_PATH" --out "$TEMP_DIR/small.png" &> /dev/null
        sips -z 100 100 "$LOGO_PATH" --out "$TEMP_DIR/medium.png" &> /dev/null
        sips -z 500 500 "$LOGO_PATH" --out "$TEMP_DIR/large.png" &> /dev/null

        # Create JPEG version
        sips -s format jpeg -z 100 100 "$LOGO_PATH" --out "$TEMP_DIR/test.jpg" &> /dev/null
    else
        cp "$LOGO_PATH" "$TEMP_DIR/small.png"
        cp "$LOGO_PATH" "$TEMP_DIR/medium.png"
        cp "$LOGO_PATH" "$TEMP_DIR/large.png"
    fi
else
    echo "Logo not found, generating test images..."
    # PNG images
    generate_test_png 16 "$TEMP_DIR/small.png"
    generate_test_png 100 "$TEMP_DIR/medium.png"
    generate_test_png 500 "$TEMP_DIR/large.png"

    # JPEG images
    generate_test_jpeg 100 "$TEMP_DIR/test.jpg"
fi

# Binary data
generate_binary 64 "$TEMP_DIR/small.bin"
generate_binary 1024 "$TEMP_DIR/1kb.bin"
generate_binary 10240 "$TEMP_DIR/10kb.bin"

# Publish test messages
echo ""
echo "Publishing messages..."

# MQTTAnalyzer logo (full size)
if [ -f "$TEMP_DIR/logo.png" ]; then
    publish_file "test/binary/logo" "$TEMP_DIR/logo.png" "MQTTAnalyzer Logo PNG"
fi

# Images (resized versions)
publish_file "test/binary/png/small" "$TEMP_DIR/small.png" "16x16 PNG"
publish_file "test/binary/png/medium" "$TEMP_DIR/medium.png" "100x100 PNG"
publish_file "test/binary/png/large" "$TEMP_DIR/large.png" "500x500 PNG"
publish_file "test/binary/jpeg/test" "$TEMP_DIR/test.jpg" "100x100 JPEG"

# Raw binary
publish_file "test/binary/raw/small" "$TEMP_DIR/small.bin" "64 bytes binary"
publish_file "test/binary/raw/1kb" "$TEMP_DIR/1kb.bin" "1KB binary"
publish_file "test/binary/raw/10kb" "$TEMP_DIR/10kb.bin" "10KB binary"

echo ""
echo "Done! Published binary test messages to test/binary/*"
