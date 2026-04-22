import wave
import struct
def convert_to_16bit_pcm(input_path, output_path):
    with open(input_path, 'rb') as f:
        f.read(12)
        while True:
            header = f.read(8)
            if not header or len(header) < 8: break
            chunk_id = header[:4]
            chunk_size = struct.unpack('<I', header[4:8])[0]
            if chunk_id == b'fmt ':
                fmt_data = f.read(chunk_size)
                channels = struct.unpack('<H', fmt_data[2:4])[0]
                rate = struct.unpack('<I', fmt_data[4:8])[0]
                if chunk_size > 16: f.read(chunk_size - 16)
            elif chunk_id == b'data':
                data = f.read(chunk_size)
                break
            else:
                f.seek(chunk_size, 1)
    out_data = bytearray()
    for i in range(0, len(data), 3):
        if i+2 < len(data):
            out_data.append(data[i+1])
            out_data.append(data[i+2])
    with wave.open(output_path, 'wb') as wav_out:
        wav_out.setnchannels(channels)
        wav_out.setsampwidth(2)
        wav_out.setframerate(rate)
        wav_out.writeframes(out_data)
try:
    convert_to_16bit_pcm('assets/Sfx/hitting.wav', 'assets/Sfx/hitting_fixed.wav')
    print('Success')
except Exception as e:
    print('Error:', e)
