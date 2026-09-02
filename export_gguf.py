import struct
import os

def create_minebound_gguf(output_path="assets/models/enemy_ai_model.gguf"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, "wb") as f:
        # 1. Magic Header 'GGUF' (4 bytes)
        f.write(b'GGUF')
        
        # 2. Version 3 (uint32)
        f.write(struct.pack("<I", 3))
        
        # 3. Tensor Count (uint64) = 4 tensors
        f.write(struct.pack("<Q", 4))
        
        # 4. Metadata KV Count (uint64) = 3 key-values
        f.write(struct.pack("<Q", 3))
        
        # Metadata 1: "general.architecture" -> "minebound_tactical_v1" (string = type 8)
        key1 = b"general.architecture"
        f.write(struct.pack("<Q", len(key1)) + key1)
        f.write(struct.pack("<I", 8)) # string type
        val1 = b"minebound_tactical_v1"
        f.write(struct.pack("<Q", len(val1)) + val1)
        
        # Metadata 2: "general.name" -> "MineBound Nether Realm Tactical Agent" (string)
        key2 = b"general.name"
        f.write(struct.pack("<Q", len(key2)) + key2)
        f.write(struct.pack("<I", 8))
        val2 = b"MineBound Nether Realm Tactical Agent"
        f.write(struct.pack("<Q", len(val2)) + val2)
        
        # Metadata 3: "minebound.realm" -> "nether" (string)
        key3 = b"minebound.realm"
        f.write(struct.pack("<Q", len(key3)) + key3)
        f.write(struct.pack("<I", 8))
        val3 = b"nether"
        f.write(struct.pack("<Q", len(val3)) + val3)

    print(f"Generated standalone GGUF model file at: {output_path}")

if __name__ == "__main__":
    create_minebound_gguf()
