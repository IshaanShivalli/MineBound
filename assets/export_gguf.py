import struct
import os
import math
import numpy as np

def create_minebound_gguf(output_path="assets/models/enemy_ai_model.gguf"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Define Neural Network Architecture for Tactical Decision Maker
    # Input Features (16 inputs):
    #   [hero_in_realm, hero_dist_to_anchor, hero_dist_to_nexus, hero_hp,
    #    nexus_hp, anchor_hp, ai_coins, ai_ores, ai_gems,
    #    player_minion_count, ai_minion_count, wave_timer,
    #    turret_count, wall_count, healing_chamber_count, player_threat_level]
    #
    # Hidden Layer 1: 16 -> 32
    # Hidden Layer 2: 32 -> 16
    # Output Layer: 16 -> 6 (Actions: 1: Wall, 2: Turret, 3: Sanctuary, 4: Rebuild Anchor, 5: Aggressive Minion Rush, 6: Save)
    
    np.random.seed(42)
    w1 = np.random.randn(16, 32).astype(np.float32) * 0.25
    b1 = np.zeros(32, dtype=np.float32)
    w2 = np.random.randn(32, 16).astype(np.float32) * 0.25
    b2 = np.zeros(16, dtype=np.float32)
    w3 = np.random.randn(16, 6).astype(np.float32) * 0.3
    b3 = np.zeros(6, dtype=np.float32)
    
    tensors = [
        ("tactical_net.layer1.weight", w1),
        ("tactical_net.layer1.bias", b1),
        ("tactical_net.layer2.weight", w2),
        ("tactical_net.layer2.bias", b2),
        ("tactical_net.layer3.weight", w3),
        ("tactical_net.layer3.bias", b3),
    ]
    
    with open(output_path, "wb") as f:
        # 1. GGUF Magic Header
        f.write(b'GGUF')
        
        # 2. Version 3 (uint32)
        f.write(struct.pack("<I", 3))
        
        # 3. Tensor Count (uint64)
        f.write(struct.pack("<Q", len(tensors)))
        
        # 4. Metadata KV Count (uint64)
        metadata = [
            ("general.architecture", "minebound_tactical_mlp_v3"),
            ("general.name", "MineBound Dual-Realm Tactical Policy Network (Full Weights)"),
            ("minebound.input_dim", 16),
            ("minebound.hidden_dim", 32),
            ("minebound.output_dim", 6),
            ("minebound.quantization", "F32_FULL_PRECISION"),
        ]
        f.write(struct.pack("<Q", len(metadata)))
        
        for k, v in metadata:
            kb = k.encode('utf-8')
            f.write(struct.pack("<Q", len(kb)) + kb)
            if isinstance(v, str):
                f.write(struct.pack("<I", 8)) # String type
                vb = v.encode('utf-8')
                f.write(struct.pack("<Q", len(vb)) + vb)
            elif isinstance(v, int):
                f.write(struct.pack("<I", 4)) # UInt32 type
                f.write(struct.pack("<I", v))

        # 5. Tensor Information Headers
        # Calculate tensor offset positions
        offset_cursor = 0
        tensor_headers = []
        for name, arr in tensors:
            nb = name.encode('utf-8')
            shape = list(arr.shape)
            n_dims = len(shape)
            data_bytes = arr.tobytes()
            tensor_headers.append((nb, n_dims, shape, offset_cursor, data_bytes))
            offset_cursor += len(data_bytes)
            
        for nb, n_dims, shape, offset, data_bytes in tensor_headers:
            f.write(struct.pack("<Q", len(nb)) + nb)
            f.write(struct.pack("<I", n_dims))
            for dim in shape:
                f.write(struct.pack("<Q", dim))
            f.write(struct.pack("<I", 0)) # GGML_TYPE_F32 = 0
            f.write(struct.pack("<Q", offset))
            
        # 6. Tensor Binary Payload Data
        for _, _, _, _, data_bytes in tensor_headers:
            f.write(data_bytes)

    file_size_kb = os.path.getsize(output_path) / 1024.0
    print(f"Generated standalone full-weight GGUF model ({file_size_kb:.2f} KB) at: {output_path}")

def create_pet_gguf(output_path="assets/models/pet_ai_model.gguf"):
    create_minebound_gguf(output_path)

if __name__ == "__main__":
    create_minebound_gguf()
    create_pet_gguf()
