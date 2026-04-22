import struct
def inspect_wav(file_path):
    try:
        with open(file_path, 'rb') as f:
            riff = f.read(12)
            print(f"{file_path} RIFF: {riff}")
            while True:
                chunk_header = f.read(8)
                if not chunk_header or len(chunk_header) < 8: break
                chunk_id = chunk_header[:4]
                chunk_size = struct.unpack('<I', chunk_header[4:8])[0]
                print(f"Chunk: {chunk_id}, Size: {chunk_size}")
                if chunk_id == b'fmt ':
                    fmt_data = f.read(chunk_size)
                    audio_format = struct.unpack('<H', fmt_data[:2])[0]
                    channels = struct.unpack('<H', fmt_data[2:4])[0]
                    sample_rate = struct.unpack('<I', fmt_data[4:8])[0]
                    bits_per_sample = struct.unpack('<H', fmt_data[14:16])[0]
                    print(f"Format: {audio_format}, Channels: {channels}, Rate: {sample_rate}, Bits: {bits_per_sample}")
                    if chunk_size > 16: f.read(chunk_size - 16)
                else:
                    f.seek(chunk_size, 1)
    except Exception as e:
        print(e)
inspect_wav('assets/Sfx/hitting.wav')
inspect_wav('assets/Sfx/lossing.wav')
