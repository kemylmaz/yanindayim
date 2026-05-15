"""
Build script: takes assets/knowledge_base/chunks.json (without embeddings)
and adds 'embedding' arrays to each chunk by running the multilingual MiniLM model.

Usage:
    pip install sentence-transformers
    python scripts/build_knowledge_base.py

Output: overwrites assets/knowledge_base/chunks.json with embeddings filled in.

Runtime on a laptop CPU: ~30 seconds for 32 chunks. GPU not required.
"""

import json
import os
from pathlib import Path

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("ERROR: sentence-transformers not installed.")
    print("Run: pip install sentence-transformers")
    raise SystemExit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
CHUNKS_PATH = REPO_ROOT / "assets" / "knowledge_base" / "chunks.json"
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"


def main() -> None:
    if not CHUNKS_PATH.exists():
        print(f"ERROR: {CHUNKS_PATH} not found")
        raise SystemExit(1)

    with CHUNKS_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)

    chunks = data["chunks"]
    print(f"Loading model {MODEL_NAME} (first run downloads ~480 MB)...")
    model = SentenceTransformer(MODEL_NAME)

    print(f"Encoding {len(chunks)} chunks...")
    texts = [c["title"] + ". " + c["text"] for c in chunks]
    embeddings = model.encode(texts, show_progress_bar=True, normalize_embeddings=True)

    for chunk, emb in zip(chunks, embeddings):
        chunk["embedding"] = [round(float(x), 6) for x in emb.tolist()]

    data["embeddingDimensions"] = len(embeddings[0])
    data["embeddingsGenerated"] = True

    with CHUNKS_PATH.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Done. Wrote {len(chunks)} embeddings to {CHUNKS_PATH}")
    print(f"File size: {CHUNKS_PATH.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
